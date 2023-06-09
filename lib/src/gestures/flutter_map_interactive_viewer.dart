import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/src/gestures/flutter_map_state_controller.dart';
import 'package:flutter_map/src/gestures/interactive_flag.dart';
import 'package:flutter_map/src/gestures/latlng_tween.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/gestures/multi_finger_gesture.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:flutter_map/src/map/options.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:flutter_map/src/misc/private/positioned_tap_detector_2.dart';
import 'package:latlong2/latlong.dart';

class FlutterMapInteractiveViewer extends StatefulWidget {
  final Widget Function(BuildContext context, FlutterMapState mapState) builder;
  final MapOptions options;
  final FlutterMapStateController controller;

  const FlutterMapInteractiveViewer({
    super.key,
    required this.builder,
    required this.options,
    required this.controller,
  });

  @override
  State<FlutterMapInteractiveViewer> createState() =>
      FlutterMapInteractiveViewerState();
}

class FlutterMapInteractiveViewerState
    extends State<FlutterMapInteractiveViewer> with TickerProviderStateMixin {
  static const int _kMinFlingVelocity = 800;
  static const _kDoubleTapZoomDuration = 200;

  final _positionedTapController = PositionedTapController();
  final _gestureArenaTeam = GestureArenaTeam();
  late Map<Type, GestureRecognizerFactory> _gestures;

  bool _dragMode = false;
  int _gestureWinner = MultiFingerGesture.none;
  int _pointerCounter = 0;
  bool _isListeningForInterruptions = false;

  var _rotationStarted = false;
  var _pinchZoomStarted = false;
  var _pinchMoveStarted = false;
  var _dragStarted = false;
  var _flingAnimationStarted = false;

  // Helps to reset ScaleUpdateDetails.scale back to 1.0 when a multi finger
  // gesture wins
  late double _scaleCorrector;
  late double _lastRotation;
  late double _lastScale;
  late Offset _lastFocalLocal;
  late LatLng _mapCenterStart;
  late double _mapZoomStart;
  late Offset _focalStartLocal;
  late LatLng _focalStartLatLng;

  late final AnimationController _flingController;
  late Animation<Offset> _flingAnimation;

  late final AnimationController _doubleTapController;
  late Animation<double> _doubleTapZoomAnimation;
  late Animation<LatLng> _doubleTapCenterAnimation;

  int _tapUpCounter = 0;
  Timer? _doubleTapHoldMaxDelay;

  @override
  void initState() {
    super.initState();
    widget.controller.interactiveViewerState = this;
    widget.controller.addListener(_onMapStateChange);
    _flingController = AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation)
      ..addStatusListener(_flingAnimationStatusListener);
    _doubleTapController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: _kDoubleTapZoomDuration,
      ),
    )
      ..addListener(_handleDoubleTapZoomAnimation)
      ..addStatusListener(_doubleTapZoomStatusListener);
  }

  void _onMapStateChange() {
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    _gestures = _initializeGestures(
      MediaQuery.gestureSettingsOf(context),
      dragEnabled: InteractiveFlag.hasFlag(
          widget.options.interactiveFlags, InteractiveFlag.drag),
    );
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(FlutterMapInteractiveViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldFlags = oldWidget.options.interactiveFlags;
    final flags = widget.options.interactiveFlags;

    final oldGestures =
        _getMultiFingerGestureFlags(mapOptions: oldWidget.options);
    final gestures = _getMultiFingerGestureFlags();

    if (flags != oldFlags) {
      _gestures = _initializeGestures(
        MediaQuery.gestureSettingsOf(context),
        dragEnabled: InteractiveFlag.hasFlag(
            widget.options.interactiveFlags, InteractiveFlag.drag),
      );
    }

    if (flags != oldFlags || gestures != oldGestures) {
      var emitMapEventMoveEnd = false;

      if (!InteractiveFlag.hasFlag(flags, InteractiveFlag.flingAnimation)) {
        _closeFlingAnimationController(MapEventSource.interactiveFlagsChanged);
      }
      if (!InteractiveFlag.hasFlag(flags, InteractiveFlag.doubleTapZoom)) {
        _closeDoubleTapController(MapEventSource.interactiveFlagsChanged);
      }

      if (_rotationStarted &&
          !(InteractiveFlag.hasFlag(flags, InteractiveFlag.rotate) &&
              MultiFingerGesture.hasFlag(
                  gestures, MultiFingerGesture.rotate))) {
        _rotationStarted = false;

        if (_gestureWinner == MultiFingerGesture.rotate) {
          _gestureWinner = MultiFingerGesture.none;
        }

        widget.controller.rotateEnded(MapEventSource.interactiveFlagsChanged);
      }

      if (_pinchZoomStarted &&
          !(InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchZoom) &&
              MultiFingerGesture.hasFlag(
                  gestures, MultiFingerGesture.pinchZoom))) {
        _pinchZoomStarted = false;
        emitMapEventMoveEnd = true;

        if (_gestureWinner == MultiFingerGesture.pinchZoom) {
          _gestureWinner = MultiFingerGesture.none;
        }
      }

      if (_pinchMoveStarted &&
          !(InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchMove) &&
              MultiFingerGesture.hasFlag(
                  gestures, MultiFingerGesture.pinchMove))) {
        _pinchMoveStarted = false;
        emitMapEventMoveEnd = true;

        if (_gestureWinner == MultiFingerGesture.pinchMove) {
          _gestureWinner = MultiFingerGesture.none;
        }
      }

      if (_dragStarted &&
          !InteractiveFlag.hasFlag(flags, InteractiveFlag.drag)) {
        _dragStarted = false;
        emitMapEventMoveEnd = true;
      }

      if (emitMapEventMoveEnd) {
        widget.controller.moveEnded(MapEventSource.interactiveFlagsChanged);
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onMapStateChange);
    _flingController.dispose();
    _doubleTapController.dispose();

    super.dispose();
  }

  Map<Type, GestureRecognizerFactory> _initializeGestures(
    DeviceGestureSettings gestureSettings, {
    required bool dragEnabled,
  }) {
    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};

    gestures[TapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
      () => TapGestureRecognizer(debugOwner: this),
      (TapGestureRecognizer instance) {
        instance
          ..onTapDown = _positionedTapController.onTapDown
          ..onTapUp = _handleOnTapUp
          ..onTap = _positionedTapController.onTap
          ..onSecondaryTap = _positionedTapController.onSecondaryTap
          ..onSecondaryTapDown = _positionedTapController.onTapDown;
      },
    );

    gestures[LongPressGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
      () => LongPressGestureRecognizer(debugOwner: this),
      (LongPressGestureRecognizer instance) {
        instance.onLongPress = _positionedTapController.onLongPress;
      },
    );

    if (dragEnabled) {
      gestures[VerticalDragGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
        () => VerticalDragGestureRecognizer(debugOwner: this),
        (VerticalDragGestureRecognizer instance) {
          instance.onUpdate = (details) {
            // Absorbing vertical drags
          };
          instance.gestureSettings = gestureSettings;
          instance.team ??= _gestureArenaTeam;
        },
      );
      gestures[HorizontalDragGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
        () => HorizontalDragGestureRecognizer(debugOwner: this),
        (HorizontalDragGestureRecognizer instance) {
          instance.onUpdate = (details) {
            // Absorbing horizontal drags
          };
          instance.gestureSettings = gestureSettings;
          instance.team ??= _gestureArenaTeam;
        },
      );
    }

    gestures[ScaleGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
      () => ScaleGestureRecognizer(debugOwner: this),
      (ScaleGestureRecognizer instance) {
        instance
          ..onStart = _handleScaleStart
          ..onUpdate = _handleScaleUpdate
          ..onEnd = _handleScaleEnd;
        instance.team ??= _gestureArenaTeam;
        _gestureArenaTeam.captain = instance;
      },
    );

    return gestures;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      onPointerHover: _onPointerHover,
      onPointerSignal: _onPointerSignal,
      child: PositionedTapDetector2(
        controller: _positionedTapController,
        onTap: _handleTap,
        onSecondaryTap: _handleSecondaryTap,
        onLongPress: _handleLongPress,
        onDoubleTap: _handleDoubleTap,
        doubleTapDelay: InteractiveFlag.hasFlag(
          widget.options.interactiveFlags,
          InteractiveFlag.doubleTapZoom,
        )
            ? null
            : Duration.zero,
        child: RawGestureDetector(
          gestures: _gestures,
          child: widget.builder(context, widget.controller.value),
        ),
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    ++_pointerCounter;

    if (widget.options.onPointerDown != null) {
      final latlng = widget.controller.value.offsetToCrs(event.localPosition);
      widget.options.onPointerDown!(event, latlng);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    --_pointerCounter;

    if (widget.options.onPointerUp != null) {
      final latlng = widget.controller.value.offsetToCrs(event.localPosition);
      widget.options.onPointerUp!(event, latlng);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    --_pointerCounter;

    if (widget.options.onPointerCancel != null) {
      final latlng = widget.controller.value.offsetToCrs(event.localPosition);
      widget.options.onPointerCancel!(event, latlng);
    }
  }

  void _onPointerHover(PointerHoverEvent event) {
    if (widget.options.onPointerHover != null) {
      final latlng = widget.controller.value.offsetToCrs(event.localPosition);
      widget.options.onPointerHover!(event, latlng);
    }
  }

  void _onPointerSignal(PointerSignalEvent pointerSignal) {
    // Handle mouse scroll events if the enableScrollWheel parameter is enabled
    if (pointerSignal is PointerScrollEvent &&
        widget.options.enableScrollWheel &&
        pointerSignal.scrollDelta.dy != 0) {
      // Prevent scrolling of parent/child widgets simultaneously. See
      // [PointerSignalResolver] documentation for more information.
      GestureBinding.instance.pointerSignalResolver.register(
        pointerSignal,
        (pointerSignal) {
          pointerSignal as PointerScrollEvent;
          final minZoom = widget.options.minZoom ?? 0.0;
          final maxZoom = widget.options.maxZoom ?? double.infinity;
          final newZoom = (widget.controller.value.zoom -
                  pointerSignal.scrollDelta.dy *
                      widget.options.scrollWheelVelocity)
              .clamp(minZoom, maxZoom);
          // Calculate offset of mouse cursor from viewport center
          final newCenter = widget.controller.value.focusedZoomCenter(
            pointerSignal.localPosition.toCustomPoint(),
            newZoom,
          );
          widget.controller.move(
            newCenter,
            newZoom,
            offset: Offset.zero,
            hasGesture: false,
            source: MapEventSource.scrollWheel,
            id: null,
          );
        },
      );
    }
  }

  void _yieldMultiFingerGestureWinner(
      int gestureWinner, bool resetStartVariables) {
    _gestureWinner = gestureWinner;

    if (resetStartVariables) {
      // note: here we could reset to current values instead of last values
      _scaleCorrector = 1.0 - _lastScale;
    }
  }

  int _getMultiFingerGestureFlags({
    int? gestureWinner,
    MapOptions? mapOptions,
  }) {
    gestureWinner ??= _gestureWinner;
    mapOptions ??= widget.options;

    if (mapOptions.enableMultiFingerGestureRace) {
      if (gestureWinner == MultiFingerGesture.pinchZoom) {
        return mapOptions.pinchZoomWinGestures;
      } else if (gestureWinner == MultiFingerGesture.rotate) {
        return mapOptions.rotationWinGestures;
      } else if (gestureWinner == MultiFingerGesture.pinchMove) {
        return mapOptions.pinchMoveWinGestures;
      }

      return MultiFingerGesture.none;
    } else {
      return MultiFingerGesture.all;
    }
  }

  void _closeFlingAnimationController(MapEventSource source) {
    _flingAnimationStarted = false;
    if (_flingController.isAnimating) {
      _flingController.stop();

      _stopListeningForAnimationInterruptions();

      widget.controller.flingEnded(source);
    }
  }

  void _closeDoubleTapController(MapEventSource source) {
    if (_doubleTapController.isAnimating) {
      _doubleTapController.stop();

      _stopListeningForAnimationInterruptions();

      widget.controller.doubleTapZoomEnded(source);
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _dragMode = _pointerCounter == 1;

    final eventSource = _dragMode
        ? MapEventSource.dragStart
        : MapEventSource.multiFingerGestureStart;
    _closeFlingAnimationController(eventSource);
    _closeDoubleTapController(eventSource);

    _gestureWinner = MultiFingerGesture.none;

    _mapZoomStart = widget.controller.value.zoom;
    _mapCenterStart = widget.controller.value.center;
    _focalStartLocal = _lastFocalLocal = details.localFocalPoint;
    _focalStartLatLng = widget.controller.value.offsetToCrs(_focalStartLocal);

    _dragStarted = false;
    _pinchZoomStarted = false;
    _pinchMoveStarted = false;
    _rotationStarted = false;

    _lastRotation = 0.0;
    _scaleCorrector = 0.0;
    _lastScale = 1.0;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_tapUpCounter == 1) {
      _handleDoubleTapHold(details);
      return;
    }

    final eventSource =
        _dragMode ? MapEventSource.onDrag : MapEventSource.onMultiFinger;

    final flags = widget.options.interactiveFlags;
    final focalOffset = details.localFocalPoint;

    final currentRotation = radianToDeg(details.rotation);

    if (_dragMode) {
      if (InteractiveFlag.hasFlag(flags, InteractiveFlag.drag)) {
        if (!_dragStarted) {
          // We could emit start event at [handleScaleStart], however it is
          // possible drag will be disabled during ongoing drag then
          // [didUpdateWidget] will emit MapEventMoveEnd and if drag is enabled
          // again then this will emit the start event again.
          _dragStarted = true;
          widget.controller.moveStarted(eventSource);
        }

        final localDistanceOffset =
            _rotateOffset(_lastFocalLocal - focalOffset);

        widget.controller.dragUpdated(eventSource, localDistanceOffset);
      }
    } else {
      final hasIntPinchMove =
          InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchMove);
      final hasIntPinchZoom =
          InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchZoom);
      final hasIntRotate =
          InteractiveFlag.hasFlag(flags, InteractiveFlag.rotate);

      if (hasIntPinchMove || hasIntPinchZoom || hasIntRotate) {
        final hasGestureRace = widget.options.enableMultiFingerGestureRace;

        if (hasGestureRace && _gestureWinner == MultiFingerGesture.none) {
          if (hasIntPinchZoom &&
              (_getZoomForScale(_mapZoomStart, details.scale) - _mapZoomStart)
                      .abs() >=
                  widget.options.pinchZoomThreshold) {
            if (widget.options.debugMultiFingerGestureWinner) {
              debugPrint('Multi Finger Gesture winner: Pinch Zoom');
            }
            _yieldMultiFingerGestureWinner(MultiFingerGesture.pinchZoom, true);
          } else if (hasIntRotate &&
              currentRotation.abs() >= widget.options.rotationThreshold) {
            if (widget.options.debugMultiFingerGestureWinner) {
              debugPrint('Multi Finger Gesture winner: Rotate');
            }
            _yieldMultiFingerGestureWinner(MultiFingerGesture.rotate, true);
          } else if (hasIntPinchMove &&
              (_focalStartLocal - focalOffset).distance >=
                  widget.options.pinchMoveThreshold) {
            if (widget.options.debugMultiFingerGestureWinner) {
              debugPrint('Multi Finger Gesture winner: Pinch Move');
            }
            _yieldMultiFingerGestureWinner(MultiFingerGesture.pinchMove, true);
          }
        }

        if (!hasGestureRace || _gestureWinner != MultiFingerGesture.none) {
          final gestures = _getMultiFingerGestureFlags();

          final hasGesturePinchMove = MultiFingerGesture.hasFlag(
              gestures, MultiFingerGesture.pinchMove);
          final hasGesturePinchZoom = MultiFingerGesture.hasFlag(
              gestures, MultiFingerGesture.pinchZoom);
          final hasGestureRotate =
              MultiFingerGesture.hasFlag(gestures, MultiFingerGesture.rotate);

          final hasMove = hasIntPinchMove && hasGesturePinchMove;
          final hasZoom = hasIntPinchZoom && hasGesturePinchZoom;
          final hasRotate = hasIntRotate && hasGestureRotate;

          if (hasMove || hasZoom) {
            double newZoom;
            // checking details.scale to prevent situation whew details comes
            // with zero scale
            if (hasZoom && details.scale > 0.0) {
              newZoom = _getZoomForScale(
                  _mapZoomStart, details.scale + _scaleCorrector);

              if (!_pinchZoomStarted) {
                if (newZoom != _mapZoomStart) {
                  _pinchZoomStarted = true;

                  if (!_pinchMoveStarted) {
                    // emit MoveStart event only if pinchMove hasn't started
                    widget.controller.moveStarted(eventSource);
                  }
                }
              }
            } else {
              newZoom = widget.controller.value.zoom;
            }

            LatLng newCenter;
            if (hasMove) {
              if (!_pinchMoveStarted && _lastFocalLocal != focalOffset) {
                _pinchMoveStarted = true;

                if (!_pinchZoomStarted) {
                  // emit MoveStart event only if pinchZoom hasn't started
                  widget.controller.moveStarted(eventSource);
                }
              }

              if (_pinchZoomStarted || _pinchMoveStarted) {
                final oldCenterPt = widget.controller.value
                    .project(widget.controller.value.center, newZoom);
                final newFocalLatLong = widget.controller.value
                    .offsetToCrs(_focalStartLocal, newZoom);
                final newFocalPt =
                    widget.controller.value.project(newFocalLatLong, newZoom);
                final oldFocalPt =
                    widget.controller.value.project(_focalStartLatLng, newZoom);
                final zoomDifference = oldFocalPt - newFocalPt;
                final moveDifference =
                    _rotateOffset(_focalStartLocal - _lastFocalLocal);

                final newCenterPt = oldCenterPt +
                    zoomDifference +
                    moveDifference.toCustomPoint();
                newCenter =
                    widget.controller.value.unproject(newCenterPt, newZoom);
              } else {
                newCenter = widget.controller.value.center;
              }
            } else {
              newCenter = widget.controller.value.center;
            }

            if (_pinchZoomStarted || _pinchMoveStarted) {
              widget.controller.move(
                newCenter,
                newZoom,
                offset: Offset.zero,
                hasGesture: true,
                source: eventSource,
                id: null,
              );
            }
          }

          if (hasRotate) {
            if (!_rotationStarted && currentRotation != 0.0) {
              _rotationStarted = true;
              widget.controller.rotateStarted(eventSource);
            }

            if (_rotationStarted) {
              final rotationDiff = currentRotation - _lastRotation;
              final oldCenterPt = widget.controller.value
                  .project(widget.controller.value.center);
              final rotationCenter = widget.controller.value.project(
                  widget.controller.value.offsetToCrs(_lastFocalLocal));
              final vector = oldCenterPt - rotationCenter;
              final rotatedVector = vector.rotate(degToRadian(rotationDiff));
              final newCenter = rotationCenter + rotatedVector;

              widget.controller.moveAndRotate(
                widget.controller.value.unproject(newCenter),
                widget.controller.value.zoom,
                widget.controller.value.rotation + rotationDiff,
                offset: Offset.zero,
                hasGesture: true,
                source: eventSource,
                id: null,
              );
            }
          }
        }
      }
    }

    _lastRotation = currentRotation;
    _lastScale = details.scale;
    _lastFocalLocal = focalOffset;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _resetDoubleTapHold();

    final eventSource =
        _dragMode ? MapEventSource.dragEnd : MapEventSource.multiFingerEnd;

    if (_rotationStarted) {
      _rotationStarted = false;
      widget.controller.rotateEnded(eventSource);
    }

    if (_dragStarted || _pinchZoomStarted || _pinchMoveStarted) {
      _dragStarted = _pinchZoomStarted = _pinchMoveStarted = false;
      widget.controller.moveEnded(eventSource);
    }

    final hasFling = InteractiveFlag.hasFlag(
        widget.options.interactiveFlags, InteractiveFlag.flingAnimation);

    final magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity || !hasFling) {
      if (hasFling) widget.controller.flingNotStarted(eventSource);
      return;
    }

    final direction = details.velocity.pixelsPerSecond / magnitude;
    final distance = (Offset.zero &
            Size(widget.controller.value.nonRotatedSize.x,
                widget.controller.value.nonRotatedSize.y))
        .shortestSide;

    final flingOffset = _focalStartLocal - _lastFocalLocal;
    _flingAnimation = Tween<Offset>(
      begin: flingOffset,
      end: flingOffset - direction * distance,
    ).animate(_flingController);

    _flingController
      ..value = 0.0
      ..fling(
          velocity: magnitude / 1000.0,
          springDescription: SpringDescription.withDampingRatio(
            mass: 1,
            stiffness: 1000,
            ratio: 5,
          ));
  }

  void _handleTap(TapPosition position) {
    _closeFlingAnimationController(MapEventSource.tap);
    _closeDoubleTapController(MapEventSource.tap);

    final relativePosition = position.relative;
    if (relativePosition == null) return;

    widget.controller.tapped(
      MapEventSource.tap,
      position,
      widget.controller.value.offsetToCrs(relativePosition),
    );
  }

  void _handleSecondaryTap(TapPosition position) {
    _closeFlingAnimationController(MapEventSource.secondaryTap);
    _closeDoubleTapController(MapEventSource.secondaryTap);

    final relativePosition = position.relative;
    if (relativePosition == null) return;

    widget.controller.secondaryTapped(
      MapEventSource.secondaryTap,
      position,
      widget.controller.value.offsetToCrs(relativePosition),
    );
  }

  void _handleLongPress(TapPosition position) {
    _resetDoubleTapHold();

    _closeFlingAnimationController(MapEventSource.longPress);
    _closeDoubleTapController(MapEventSource.longPress);

    widget.controller.longPressed(
      MapEventSource.longPress,
      position,
      widget.controller.value.offsetToCrs(position.relative!),
    );
  }

  void _handleDoubleTap(TapPosition tapPosition) {
    _resetDoubleTapHold();

    _closeFlingAnimationController(MapEventSource.doubleTap);
    _closeDoubleTapController(MapEventSource.doubleTap);

    if (InteractiveFlag.hasFlag(
        widget.options.interactiveFlags, InteractiveFlag.doubleTapZoom)) {
      final newZoom = _getZoomForScale(widget.controller.zoom, 2);
      final newCenter = widget.controller.value.focusedZoomCenter(
        tapPosition.relative!.toCustomPoint(),
        newZoom,
      );
      _startDoubleTapAnimation(newZoom, newCenter);
    }
  }

  void _startDoubleTapAnimation(double newZoom, LatLng newCenter) {
    _doubleTapZoomAnimation =
        Tween<double>(begin: widget.controller.value.zoom, end: newZoom)
            .chain(CurveTween(curve: Curves.linear))
            .animate(_doubleTapController);
    _doubleTapCenterAnimation =
        LatLngTween(begin: widget.controller.value.center, end: newCenter)
            .chain(CurveTween(curve: Curves.linear))
            .animate(_doubleTapController);
    _doubleTapController.forward(from: 0);
  }

  void _doubleTapZoomStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      widget.controller.doubleTapZoomStarted(
        MapEventSource.doubleTapZoomAnimationController,
      );
      _startListeningForAnimationInterruptions();
    } else if (status == AnimationStatus.completed) {
      _stopListeningForAnimationInterruptions();

      widget.controller.doubleTapZoomEnded(
        MapEventSource.doubleTapZoomAnimationController,
      );
    }
  }

  void _handleDoubleTapZoomAnimation() {
    widget.controller.move(
      _doubleTapCenterAnimation.value,
      _doubleTapZoomAnimation.value,
      offset: Offset.zero,
      hasGesture: true,
      source: MapEventSource.doubleTapZoomAnimationController,
      id: null,
    );
  }

  void _handleOnTapUp(TapUpDetails details) {
    _doubleTapHoldMaxDelay?.cancel();

    if (++_tapUpCounter == 1) {
      _doubleTapHoldMaxDelay =
          Timer(const Duration(milliseconds: 350), _resetDoubleTapHold);
    }
  }

  void _handleDoubleTapHold(ScaleUpdateDetails details) {
    _doubleTapHoldMaxDelay?.cancel();

    final flags = widget.options.interactiveFlags;
    if (InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchZoom)) {
      final verticalOffset = (_focalStartLocal - details.localFocalPoint).dy;
      final newZoom =
          _mapZoomStart - verticalOffset / 360 * widget.controller.value.zoom;

      final min = widget.options.minZoom ?? 0.0;
      final max = widget.options.maxZoom ?? double.infinity;
      final actualZoom = math.max(min, math.min(max, newZoom));

      widget.controller.move(
        widget.controller.value.center,
        actualZoom,
        offset: Offset.zero,
        hasGesture: true,
        source: MapEventSource.doubleTapHold,
        id: null,
      );
    }
  }

  void _handleFlingAnimation() {
    if (!_flingAnimationStarted) {
      _flingAnimationStarted = true;
      widget.controller.flingStarted(MapEventSource.flingAnimationController);
      _startListeningForAnimationInterruptions();
    }

    final newCenterPoint = widget.controller.value.project(_mapCenterStart) +
        _flingAnimation.value
            .toCustomPoint()
            .rotate(widget.controller.value.rotationRad);
    final newCenter = widget.controller.value.unproject(newCenterPoint);

    widget.controller.move(
      newCenter,
      widget.controller.value.zoom,
      offset: Offset.zero,
      hasGesture: true,
      source: MapEventSource.flingAnimationController,
      id: null,
    );
  }

  void _resetDoubleTapHold() {
    _doubleTapHoldMaxDelay?.cancel();
    _tapUpCounter = 0;
  }

  void _flingAnimationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _flingAnimationStarted = false;
      _stopListeningForAnimationInterruptions();
      widget.controller.flingEnded(MapEventSource.flingAnimationController);
    }
  }

  void _startListeningForAnimationInterruptions() {
    _isListeningForInterruptions = true;
  }

  void _stopListeningForAnimationInterruptions() {
    _isListeningForInterruptions = false;
  }

  void interruptAnimatedMovement(MapEvent event) {
    if (_isListeningForInterruptions) {
      _closeDoubleTapController(event.source);
      _closeFlingAnimationController(event.source);
    }
  }

  double _getZoomForScale(double startZoom, double scale) {
    final resultZoom =
        scale == 1.0 ? startZoom : startZoom + math.log(scale) / math.ln2;
    return widget.controller.value.fitZoomToBounds(resultZoom);
  }

  Offset _rotateOffset(Offset offset) {
    final radians = widget.controller.value.rotationRad;
    if (radians != 0.0) {
      final cos = math.cos(radians);
      final sin = math.sin(radians);
      final nx = (cos * offset.dx) + (sin * offset.dy);
      final ny = (cos * offset.dy) - (sin * offset.dx);

      return Offset(nx, ny);
    }

    return offset;
  }
}
