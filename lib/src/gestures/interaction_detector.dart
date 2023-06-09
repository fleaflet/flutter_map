import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/src/gestures/interactive_flag.dart';
import 'package:flutter_map/src/gestures/latlng_tween.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/gestures/multi_finger_gesture.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:flutter_map/src/map/flutter_map_state_container.dart';
import 'package:flutter_map/src/map/options.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:flutter_map/src/misc/private/positioned_tap_detector_2.dart';
import 'package:latlong2/latlong.dart';

class InteractionDetector extends StatefulWidget {
  final Widget child;
  final FlutterMapStateContainer mapStateContainer;

  FlutterMapState get mapState => mapStateContainer.mapState;
  MapOptions get options => mapState.options;

  final void Function(PointerDownEvent event) onPointerDown;
  final void Function(PointerUpEvent event) onPointerUp;
  final void Function(PointerCancelEvent event) onPointerCancel;
  final void Function(PointerHoverEvent event) onPointerHover;
  final void Function(PointerScrollEvent event) onScroll;
  final void Function(MapEventSource source, double newZoom)
      onOneFingerPinchZoom;
  final void Function(MapEventSource source) onRotateEnd;
  final void Function(MapEventSource source) onMoveEnd;
  final void Function(MapEventSource source) onFlingStart;
  final void Function(MapEventSource source) onFlingEnd;
  final void Function(MapEventSource source) onDoubleTapZoomEnd;
  final void Function(MapEventSource source) onMoveStart;
  final void Function(MapEventSource source) onRotateStart;
  final void Function(MapEventSource source) onFlingNotStarted;
  final void Function(MapEventSource source, LatLng position) onTap;
  final void Function(MapEventSource source, LatLng position) onSecondaryTap;
  final void Function(MapEventSource source, LatLng position) onLongPress;
  final void Function(MapEventSource source, Offset offset) onDragUpdate;
  final void Function(MapEventSource source, LatLng position, double zoom)
      onPinchZoomUpdate;
  final void Function(MapEventSource source, LatLng position, double zoom)
      onDoubleTapZoomUpdate;
  final void Function(
          MapEventSource source, LatLng position, double zoom, double rotation)
      onRotateUpdate;

  final void Function(MapEventSource source, LatLng position) onFlingUpdate;
  final void Function(MapEventSource source) onDoubleTapZoomStart;

  const InteractionDetector({
    super.key,
    required this.child,
    required this.mapStateContainer,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onPointerCancel,
    required this.onPointerHover,
    required this.onRotateEnd,
    required this.onMoveEnd,
    required this.onFlingEnd,
    required this.onFlingStart,
    required this.onDoubleTapZoomEnd,
    required this.onMoveStart,
    required this.onDragUpdate,
    required this.onRotateStart,
    required this.onFlingNotStarted,
    required this.onPinchZoomUpdate,
    required this.onTap,
    required this.onRotateUpdate,
    required this.onSecondaryTap,
    required this.onLongPress,
    required this.onDoubleTapZoomStart,
    required this.onScroll,
    required this.onOneFingerPinchZoom,
    required this.onDoubleTapZoomUpdate,
    required this.onFlingUpdate,
  });

  @override
  State<InteractionDetector> createState() => InteractionDetectorState();
}

class InteractionDetectorState extends State<InteractionDetector>
    with TickerProviderStateMixin {
  static const int _kMinFlingVelocity = 800;

  final _positionedTapController = PositionedTapController();
  final _gestureArenaTeam = GestureArenaTeam();

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
    _flingController = AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation)
      ..addStatusListener(_flingAnimationStatusListener);
    _doubleTapController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(_handleDoubleTapZoomAnimation)
      ..addStatusListener(_doubleTapZoomStatusListener);
  }

  @override
  void didUpdateWidget(InteractionDetector oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldFlags = oldWidget.options.interactiveFlags;
    final flags = widget.options.interactiveFlags;

    final oldGestures =
        _getMultiFingerGestureFlags(mapOptions: oldWidget.options);
    final gestures = _getMultiFingerGestureFlags();

    if (flags != oldFlags || gestures != oldGestures) {
      var emitMapEventMoveEnd = false;

      if (!InteractiveFlag.hasFlag(flags, InteractiveFlag.flingAnimation)) {
        closeFlingAnimationController(MapEventSource.interactiveFlagsChanged);
      }
      if (!InteractiveFlag.hasFlag(flags, InteractiveFlag.doubleTapZoom)) {
        closeDoubleTapController(MapEventSource.interactiveFlagsChanged);
      }

      if (_rotationStarted &&
          !(InteractiveFlag.hasFlag(flags, InteractiveFlag.rotate) &&
              MultiFingerGesture.hasFlag(
                  gestures, MultiFingerGesture.rotate))) {
        _rotationStarted = false;

        if (_gestureWinner == MultiFingerGesture.rotate) {
          _gestureWinner = MultiFingerGesture.none;
        }

        widget.onRotateEnd(MapEventSource.interactiveFlagsChanged);
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
        widget.onMoveEnd(MapEventSource.interactiveFlagsChanged);
      }
    }
  }

  @override
  void dispose() {
    _flingController.dispose();
    _doubleTapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DeviceGestureSettings gestureSettings =
        MediaQuery.gestureSettingsOf(context);
    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};

    gestures[TapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
      () => TapGestureRecognizer(debugOwner: this),
      (TapGestureRecognizer instance) {
        instance
          ..onTapDown = _positionedTapController.onTapDown
          ..onTapUp = handleOnTapUp
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

    if (InteractiveFlag.hasFlag(
        widget.options.interactiveFlags, InteractiveFlag.drag)) {
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
          ..onStart = handleScaleStart
          ..onUpdate = handleScaleUpdate
          ..onEnd = handleScaleEnd;
        instance.team ??= _gestureArenaTeam;
        _gestureArenaTeam.captain = instance;
      },
    );

    return Listener(
      onPointerDown: onPointerDown,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      onPointerHover: onPointerHover,
      onPointerSignal: onPointerSignal,
      child: PositionedTapDetector2(
        controller: _positionedTapController,
        onTap: handleTap,
        onSecondaryTap: handleSecondaryTap,
        onLongPress: handleLongPress,
        onDoubleTap: handleDoubleTap,
        doubleTapDelay: InteractiveFlag.hasFlag(
          widget.options.interactiveFlags,
          InteractiveFlag.doubleTapZoom,
        )
            ? null
            : Duration.zero,
        child: RawGestureDetector(
          gestures: gestures,
          child: widget.child,
        ),
      ),
    );
  }

  void onPointerDown(PointerDownEvent event) {
    ++_pointerCounter;
    widget.onPointerDown(event);
  }

  void onPointerUp(PointerUpEvent event) {
    --_pointerCounter;
    widget.onPointerUp(event);
  }

  void onPointerCancel(PointerCancelEvent event) {
    --_pointerCounter;
    widget.onPointerCancel(event);
  }

  void onPointerHover(PointerHoverEvent event) {
    widget.onPointerHover(event);
  }

  void onPointerSignal(PointerSignalEvent pointerSignal) {
    // Handle mouse scroll events if the enableScrollWheel parameter is enabled
    if (pointerSignal is PointerScrollEvent &&
        widget.options.enableScrollWheel &&
        pointerSignal.scrollDelta.dy != 0) {
      // Prevent scrolling of parent/child widgets simultaneously. See
      // [PointerSignalResolver] documentation for more information.
      GestureBinding.instance.pointerSignalResolver.register(
        pointerSignal,
        (pointerSignal) => widget.onScroll(pointerSignal as PointerScrollEvent),
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

  int _getMultiFingerGestureFlags(
      {int? gestureWinner, MapOptions? mapOptions}) {
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

  void closeFlingAnimationController(MapEventSource source) {
    _flingAnimationStarted = false;
    if (_flingController.isAnimating) {
      _flingController.stop();

      _stopListeningForAnimationInterruptions();

      widget.onFlingEnd(source);
    }
  }

  void closeDoubleTapController(MapEventSource source) {
    if (_doubleTapController.isAnimating) {
      _doubleTapController.stop();

      _stopListeningForAnimationInterruptions();

      widget.onDoubleTapZoomEnd(source);
    }
  }

  void handleScaleStart(ScaleStartDetails details) {
    _dragMode = _pointerCounter == 1;

    final eventSource = _dragMode
        ? MapEventSource.dragStart
        : MapEventSource.multiFingerGestureStart;
    closeFlingAnimationController(eventSource);
    closeDoubleTapController(eventSource);

    _gestureWinner = MultiFingerGesture.none;

    _mapZoomStart = widget.mapState.zoom;
    _mapCenterStart = widget.mapState.center;
    _focalStartLocal = _lastFocalLocal = details.localFocalPoint;
    _focalStartLatLng = _offsetToCrs(_focalStartLocal);

    _dragStarted = false;
    _pinchZoomStarted = false;
    _pinchMoveStarted = false;
    _rotationStarted = false;

    _lastRotation = 0.0;
    _scaleCorrector = 0.0;
    _lastScale = 1.0;
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
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
          widget.onMoveStart(eventSource);
        }

        final localDistanceOffset =
            _rotateOffset(_lastFocalLocal - focalOffset);

        widget.onDragUpdate(eventSource, localDistanceOffset);
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
                    widget.onMoveStart(eventSource);
                  }
                }
              }
            } else {
              newZoom = widget.mapState.zoom;
            }

            LatLng newCenter;
            if (hasMove) {
              if (!_pinchMoveStarted && _lastFocalLocal != focalOffset) {
                _pinchMoveStarted = true;

                if (!_pinchZoomStarted) {
                  // emit MoveStart event only if pinchZoom hasn't started
                  widget.onMoveStart(eventSource);
                }
              }

              if (_pinchZoomStarted || _pinchMoveStarted) {
                final oldCenterPt =
                    widget.mapState.project(widget.mapState.center, newZoom);
                final newFocalLatLong = _offsetToCrs(_focalStartLocal, newZoom);
                final newFocalPt =
                    widget.mapState.project(newFocalLatLong, newZoom);
                final oldFocalPt =
                    widget.mapState.project(_focalStartLatLng, newZoom);
                final zoomDifference = oldFocalPt - newFocalPt;
                final moveDifference =
                    _rotateOffset(_focalStartLocal - _lastFocalLocal);

                final newCenterPt = oldCenterPt +
                    zoomDifference +
                    _offsetToPoint(moveDifference);
                newCenter = widget.mapState.unproject(newCenterPt, newZoom);
              } else {
                newCenter = widget.mapState.center;
              }
            } else {
              newCenter = widget.mapState.center;
            }

            if (_pinchZoomStarted || _pinchMoveStarted) {
              widget.onPinchZoomUpdate(eventSource, newCenter, newZoom);
            }
          }

          if (hasRotate) {
            if (!_rotationStarted && currentRotation != 0.0) {
              _rotationStarted = true;
              widget.onRotateStart(eventSource);
            }

            if (_rotationStarted) {
              final rotationDiff = currentRotation - _lastRotation;
              final oldCenterPt =
                  widget.mapState.project(widget.mapState.center);
              final rotationCenter =
                  widget.mapState.project(_offsetToCrs(_lastFocalLocal));
              final vector = oldCenterPt - rotationCenter;
              final rotatedVector = vector.rotate(degToRadian(rotationDiff));
              final newCenter = rotationCenter + rotatedVector;

              widget.onRotateUpdate(
                eventSource,
                widget.mapState.unproject(newCenter),
                widget.mapState.zoom,
                widget.mapState.rotation + rotationDiff,
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

  void handleScaleEnd(ScaleEndDetails details) {
    _resetDoubleTapHold();

    final eventSource =
        _dragMode ? MapEventSource.dragEnd : MapEventSource.multiFingerEnd;

    if (_rotationStarted) {
      _rotationStarted = false;
      widget.onRotateEnd(eventSource);
    }

    if (_dragStarted || _pinchZoomStarted || _pinchMoveStarted) {
      _dragStarted = _pinchZoomStarted = _pinchMoveStarted = false;
      widget.onMoveEnd(eventSource);
    }

    final hasFling = InteractiveFlag.hasFlag(
        widget.options.interactiveFlags, InteractiveFlag.flingAnimation);

    final magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity || !hasFling) {
      if (hasFling) {
        widget.onFlingNotStarted(eventSource);
      }

      return;
    }

    final direction = details.velocity.pixelsPerSecond / magnitude;
    final distance = (Offset.zero &
            Size(widget.mapState.nonrotatedSize.x,
                widget.mapState.nonrotatedSize.y))
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

  void handleTap(TapPosition position) {
    closeFlingAnimationController(MapEventSource.tap);
    closeDoubleTapController(MapEventSource.tap);

    final relativePosition = position.relative;
    if (relativePosition == null) return;

    final latlng = _offsetToCrs(relativePosition);
    final onTap = widget.options.onTap;
    if (onTap != null) {
      // emit the event
      onTap(position, latlng);
    }
    widget.onTap(MapEventSource.tap, latlng);
  }

  void handleSecondaryTap(TapPosition position) {
    closeFlingAnimationController(MapEventSource.secondaryTap);
    closeDoubleTapController(MapEventSource.secondaryTap);

    final relativePosition = position.relative;
    if (relativePosition == null) return;

    final latlng = _offsetToCrs(relativePosition);
    final onSecondaryTap = widget.options.onSecondaryTap;
    if (onSecondaryTap != null) {
      // emit the event
      onSecondaryTap(position, latlng);
    }

    widget.onSecondaryTap(MapEventSource.secondaryTap, latlng);
  }

  void handleLongPress(TapPosition position) {
    _resetDoubleTapHold();

    closeFlingAnimationController(MapEventSource.longPress);
    closeDoubleTapController(MapEventSource.longPress);

    final latlng = _offsetToCrs(position.relative!);
    if (widget.options.onLongPress != null) {
      // emit the event
      widget.options.onLongPress!(position, latlng);
    }

    widget.onLongPress(MapEventSource.longPress, latlng);
  }

  LatLng _offsetToCrs(Offset offset, [double? zoom]) {
    final focalStartPt = widget.mapState
        .project(widget.mapState.center, zoom ?? widget.mapState.zoom);
    final point =
        (_offsetToPoint(offset) - (widget.mapState.nonrotatedSize / 2.0))
            .rotate(widget.mapState.rotationRad);

    final newCenterPt = focalStartPt + point;
    return widget.mapState.unproject(newCenterPt, zoom ?? widget.mapState.zoom);
  }

  void handleDoubleTap(TapPosition tapPosition) {
    _resetDoubleTapHold();

    closeFlingAnimationController(MapEventSource.doubleTap);
    closeDoubleTapController(MapEventSource.doubleTap);

    if (InteractiveFlag.hasFlag(
        widget.options.interactiveFlags, InteractiveFlag.doubleTapZoom)) {
      final centerZoom = _getNewEventCenterZoomPosition(
          _offsetToPoint(tapPosition.relative!),
          _getZoomForScale(widget.mapState.zoom, 2));
      _startDoubleTapAnimation(
          centerZoom[1] as double, centerZoom[0] as LatLng);
    }
  }

  // If we double click in the corner of a map, calculate the new
  // center of the whole map after a zoom, to retain that offset position
  // so that the same event LatLng is still under the cursor.

  List<dynamic> _getNewEventCenterZoomPosition(
      CustomPoint cursorPos, double newZoom) {
    // Calculate offset of mouse cursor from viewport center
    final viewCenter = widget.mapState.nonrotatedSize / 2;
    final offset = (cursorPos - viewCenter).rotate(widget.mapState.rotationRad);
    // Match new center coordinate to mouse cursor position
    final scale = widget.mapState.getZoomScale(newZoom, widget.mapState.zoom);
    final newOffset = offset * (1.0 - 1.0 / scale);
    final mapCenter = widget.mapState.project(widget.mapState.center);
    final newCenter = widget.mapState.unproject(mapCenter + newOffset);
    return <dynamic>[newCenter, newZoom];
  }

  void _startDoubleTapAnimation(double newZoom, LatLng newCenter) {
    _doubleTapZoomAnimation =
        Tween<double>(begin: widget.mapState.zoom, end: newZoom)
            .chain(CurveTween(curve: Curves.linear))
            .animate(_doubleTapController);
    _doubleTapCenterAnimation =
        LatLngTween(begin: widget.mapState.center, end: newCenter)
            .chain(CurveTween(curve: Curves.linear))
            .animate(_doubleTapController);
    _doubleTapController.forward(from: 0);
  }

  void _doubleTapZoomStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      widget.onDoubleTapZoomStart(
          MapEventSource.doubleTapZoomAnimationController);
      _startListeningForAnimationInterruptions();
    } else if (status == AnimationStatus.completed) {
      _stopListeningForAnimationInterruptions();
      widget
          .onDoubleTapZoomEnd(MapEventSource.doubleTapZoomAnimationController);
    }
  }

  void _handleDoubleTapZoomAnimation() {
    widget.onDoubleTapZoomUpdate(
      MapEventSource.doubleTapZoomAnimationController,
      _doubleTapCenterAnimation.value,
      _doubleTapZoomAnimation.value,
    );
  }

  void handleOnTapUp(TapUpDetails details) {
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
          _mapZoomStart - verticalOffset / 360 * widget.mapState.zoom;

      widget.onOneFingerPinchZoom(MapEventSource.doubleTapHold, newZoom);
    }
  }

  void _resetDoubleTapHold() {
    _doubleTapHoldMaxDelay?.cancel();
    _tapUpCounter = 0;
  }

  void _flingAnimationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _flingAnimationStarted = false;
      _stopListeningForAnimationInterruptions();
      widget.onFlingEnd(MapEventSource.flingAnimationController);
    }
  }

  void _handleFlingAnimation() {
    if (!_flingAnimationStarted) {
      _flingAnimationStarted = true;
      widget.onFlingStart(MapEventSource.flingAnimationController);
      _startListeningForAnimationInterruptions();
    }

    final newCenterPoint = widget.mapState.project(_mapCenterStart) +
        _offsetToPoint(_flingAnimation.value)
            .rotate(widget.mapState.rotationRad);
    final newCenter = widget.mapState.unproject(newCenterPoint);

    widget.onFlingUpdate(MapEventSource.flingAnimationController, newCenter);
  }

  void _startListeningForAnimationInterruptions() {
    _isListeningForInterruptions = true;
  }

  void _stopListeningForAnimationInterruptions() {
    _isListeningForInterruptions = false;
  }

  void handleAnimationInterruptions(MapEvent event) {
    if (_isListeningForInterruptions == false) {
      //Do not handle animation interruptions if not listening
      return;
    }
    closeDoubleTapController(event.source);
    closeFlingAnimationController(event.source);
  }

  CustomPoint<double> _offsetToPoint(Offset offset) {
    return CustomPoint(offset.dx, offset.dy);
  }

  double _getZoomForScale(double startZoom, double scale) {
    final resultZoom =
        scale == 1.0 ? startZoom : startZoom + math.log(scale) / math.ln2;
    return widget.mapState.fitZoomToBounds(resultZoom);
  }

  Offset _rotateOffset(Offset offset) {
    final radians = widget.mapState.rotationRad;
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
