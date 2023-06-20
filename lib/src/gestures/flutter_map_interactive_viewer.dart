import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/src/gestures/interactive_flag.dart';
import 'package:flutter_map/src/gestures/latlng_tween.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/gestures/multi_finger_gesture.dart';
import 'package:flutter_map/src/map/camera.dart';
import 'package:flutter_map/src/map/internal_controller.dart';
import 'package:flutter_map/src/map/options.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:flutter_map/src/misc/private/positioned_tap_detector_2.dart';
import 'package:latlong2/latlong.dart';

class FlutterMapInteractiveViewer extends StatefulWidget {
  final Widget Function(
    BuildContext context,
    MapOptions options,
    MapCamera camera,
  ) builder;
  final FlutterMapInternalController controller;

  const FlutterMapInteractiveViewer({
    super.key,
    required this.builder,
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

  late final AnimationController _flingController =
      AnimationController(vsync: this);
  late Animation<Offset> _flingAnimation;

  late final AnimationController _doubleTapController = AnimationController(
    vsync: this,
    duration: const Duration(
      milliseconds: _kDoubleTapZoomDuration,
    ),
  );
  late Animation<double> _doubleTapZoomAnimation;
  late Animation<LatLng> _doubleTapCenterAnimation;

  int _tapUpCounter = 0;
  Timer? _doubleTapHoldMaxDelay;

  MapCamera get _mapCamera => widget.controller.camera;

  MapOptions get _options => widget.controller.options;
  InteractionOptions get _interactionOptions => _options.interactionOptions;

  @override
  void initState() {
    super.initState();
    widget.controller.interactiveViewerState = this;
    widget.controller.addListener(_onMapStateChange);
    _flingController
      ..addListener(_handleFlingAnimation)
      ..addStatusListener(_flingAnimationStatusListener);
    _doubleTapController
      ..addListener(_handleDoubleTapZoomAnimation)
      ..addStatusListener(_doubleTapZoomStatusListener);
  }

  void _onMapStateChange() {
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    // _createGestures uses a MediaQuery to determine gesture settings. This
    // will update those gesture settings if they change.
    _gestures = _createGestures(
      dragEnabled: InteractiveFlag.hasDrag(_interactionOptions.flags),
    );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onMapStateChange);
    _flingController.dispose();
    _doubleTapController.dispose();

    super.dispose();
  }

  void updateGestures(
    InteractionOptions oldOptions,
    InteractionOptions newOptions,
  ) {
    if (newOptions.dragEnabled != oldOptions.dragEnabled) {
      _gestures = _createGestures(dragEnabled: newOptions.dragEnabled);
    }

    if (!newOptions.flingEnabled) {
      _closeFlingAnimationController(MapEventSource.interactiveFlagsChanged);
    }
    if (newOptions.doubleTapZoomEnabled) {
      _closeDoubleTapController(MapEventSource.interactiveFlagsChanged);
    }

    final gestures = _getMultiFingerGestureFlags(newOptions);

    if (_rotationStarted &&
        !newOptions.rotateEnabled &&
        !MultiFingerGesture.hasRotate(gestures)) {
      _rotationStarted = false;

      if (_gestureWinner == MultiFingerGesture.rotate) {
        _gestureWinner = MultiFingerGesture.none;
      }

      widget.controller.rotateEnded(MapEventSource.interactiveFlagsChanged);
    }

    var emitMapEventMoveEnd = false;

    if (_pinchZoomStarted &&
        !newOptions.pinchZoomEnabled &&
        !MultiFingerGesture.hasPinchZoom(gestures)) {
      _pinchZoomStarted = false;
      emitMapEventMoveEnd = true;

      if (_gestureWinner == MultiFingerGesture.pinchZoom) {
        _gestureWinner = MultiFingerGesture.none;
      }
    }

    if (_pinchMoveStarted &&
        !newOptions.pinchMoveEnabled &&
        !MultiFingerGesture.hasPinchMove(gestures)) {
      _pinchMoveStarted = false;
      emitMapEventMoveEnd = true;

      if (_gestureWinner == MultiFingerGesture.pinchMove) {
        _gestureWinner = MultiFingerGesture.none;
      }
    }

    if (_dragStarted && !newOptions.dragEnabled) {
      _dragStarted = false;
      emitMapEventMoveEnd = true;
    }

    if (emitMapEventMoveEnd) {
      widget.controller.moveEnded(MapEventSource.interactiveFlagsChanged);
    }
  }

  Map<Type, GestureRecognizerFactory> _createGestures({
    required bool dragEnabled,
  }) {
    final gestureSettings = MediaQuery.gestureSettingsOf(context);
    return <Type, GestureRecognizerFactory>{
      TapGestureRecognizer:
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
      ),
      LongPressGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
        () => LongPressGestureRecognizer(debugOwner: this),
        (LongPressGestureRecognizer instance) {
          instance.onLongPress = _positionedTapController.onLongPress;
        },
      ),
      if (dragEnabled)
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
          () => VerticalDragGestureRecognizer(debugOwner: this),
          (VerticalDragGestureRecognizer instance) {
            instance.onUpdate = (details) {
              // Absorbing vertical drags
            };
            instance.gestureSettings = gestureSettings;
            instance.team ??= _gestureArenaTeam;
          },
        ),
      if (dragEnabled)
        HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            HorizontalDragGestureRecognizer>(
          () => HorizontalDragGestureRecognizer(debugOwner: this),
          (HorizontalDragGestureRecognizer instance) {
            instance.onUpdate = (details) {
              // Absorbing horizontal drags
            };
            instance.gestureSettings = gestureSettings;
            instance.team ??= _gestureArenaTeam;
          },
        ),
      ScaleGestureRecognizer:
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
      ),
    };
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
        doubleTapDelay:
            InteractiveFlag.hasDoubleTapZoom(_interactionOptions.flags)
                ? null
                : Duration.zero,
        child: RawGestureDetector(
          gestures: _gestures,
          child: widget.builder(
            context,
            widget.controller.options,
            widget.controller.camera,
          ),
        ),
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    ++_pointerCounter;

    if (_options.onPointerDown != null) {
      final latlng = _mapCamera.offsetToCrs(event.localPosition);
      _options.onPointerDown!(event, latlng);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    --_pointerCounter;

    if (_options.onPointerUp != null) {
      final latlng = _mapCamera.offsetToCrs(event.localPosition);
      _options.onPointerUp!(event, latlng);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    --_pointerCounter;

    if (_options.onPointerCancel != null) {
      final latlng = _mapCamera.offsetToCrs(event.localPosition);
      _options.onPointerCancel!(event, latlng);
    }
  }

  void _onPointerHover(PointerHoverEvent event) {
    if (_options.onPointerHover != null) {
      final latlng = _mapCamera.offsetToCrs(event.localPosition);
      _options.onPointerHover!(event, latlng);
    }
  }

  void _onPointerSignal(PointerSignalEvent pointerSignal) {
    // Handle mouse scroll events if the enableScrollWheel parameter is enabled
    if (pointerSignal is PointerScrollEvent &&
        _interactionOptions.enableScrollWheel &&
        pointerSignal.scrollDelta.dy != 0) {
      // Prevent scrolling of parent/child widgets simultaneously. See
      // [PointerSignalResolver] documentation for more information.
      GestureBinding.instance.pointerSignalResolver.register(
        pointerSignal,
        (pointerSignal) {
          pointerSignal as PointerScrollEvent;
          final minZoom = _options.minZoom ?? 0.0;
          final maxZoom = _options.maxZoom ?? double.infinity;
          final newZoom = (_mapCamera.zoom -
                  pointerSignal.scrollDelta.dy *
                      _interactionOptions.scrollWheelVelocity)
              .clamp(minZoom, maxZoom);
          // Calculate offset of mouse cursor from viewport center
          final newCenter = _mapCamera.focusedZoomCenter(
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

  int _getMultiFingerGestureFlags(InteractionOptions interactionOptions) {
    if (interactionOptions.enableMultiFingerGestureRace) {
      if (_gestureWinner == MultiFingerGesture.pinchZoom) {
        return interactionOptions.pinchZoomWinGestures;
      } else if (_gestureWinner == MultiFingerGesture.rotate) {
        return interactionOptions.rotationWinGestures;
      } else if (_gestureWinner == MultiFingerGesture.pinchMove) {
        return interactionOptions.pinchMoveWinGestures;
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

    _mapZoomStart = _mapCamera.zoom;
    _mapCenterStart = _mapCamera.center;
    _focalStartLocal = _lastFocalLocal = details.localFocalPoint;
    _focalStartLatLng = _mapCamera.offsetToCrs(_focalStartLocal);

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

    final currentRotation = radianToDeg(details.rotation);
    if (_dragMode) {
      _handleScaleDragUpdate(details);
    } else if (InteractiveFlag.hasMultiFinger(_interactionOptions.flags)) {
      _handleScaleMultiFingerUpdate(details, currentRotation);
    }

    _lastRotation = currentRotation;
    _lastScale = details.scale;
    _lastFocalLocal = details.localFocalPoint;
  }

  void _handleScaleDragUpdate(ScaleUpdateDetails details) {
    const eventSource = MapEventSource.onDrag;

    if (InteractiveFlag.hasDrag(_interactionOptions.flags)) {
      if (!_dragStarted) {
        // We could emit start event at [handleScaleStart], however it is
        // possible drag will be disabled during ongoing drag then
        // [didUpdateWidget] will emit MapEventMoveEnd and if drag is enabled
        // again then this will emit the start event again.
        _dragStarted = true;
        widget.controller.moveStarted(eventSource);
      }

      final localDistanceOffset = _rotateOffset(
        _lastFocalLocal - details.localFocalPoint,
      );

      widget.controller.dragUpdated(eventSource, localDistanceOffset);
    }
  }

  void _handleScaleMultiFingerUpdate(
    ScaleUpdateDetails details,
    double currentRotation,
  ) {
    final hasGestureRace = _interactionOptions.enableMultiFingerGestureRace;

    if (hasGestureRace && _gestureWinner == MultiFingerGesture.none) {
      final gestureWinner = _determineMultiFingerGestureWinner(
        _interactionOptions.rotationThreshold,
        currentRotation,
        details.scale,
        details.localFocalPoint,
      );
      if (gestureWinner != null) {
        _gestureWinner = gestureWinner;
        // note: here we could reset to current values instead of last values
        _scaleCorrector = 1.0 - _lastScale;
      }
    }

    if (!hasGestureRace || _gestureWinner != MultiFingerGesture.none) {
      final gestures = _getMultiFingerGestureFlags(_options.interactionOptions);

      final hasPinchZoom =
          InteractiveFlag.hasPinchZoom(_interactionOptions.flags) &&
              MultiFingerGesture.hasPinchZoom(gestures);
      final hasPinchMove =
          InteractiveFlag.hasPinchMove(_interactionOptions.flags) &&
              MultiFingerGesture.hasPinchMove(gestures);
      if (hasPinchZoom || hasPinchMove) {
        _handleScalePinchZoomAndMove(details, hasPinchZoom, hasPinchMove);
      }

      if (InteractiveFlag.hasRotate(_interactionOptions.flags) &&
          MultiFingerGesture.hasRotate(gestures)) {
        _handleScalePinchRotate(details, currentRotation);
      }
    }
  }

  void _handleScalePinchZoomAndMove(
    ScaleUpdateDetails details,
    bool hasPinchZoom,
    bool hasPinchMove,
  ) {
    LatLng newCenter = _mapCamera.center;
    double newZoom = _mapCamera.zoom;

    // Handle pinch zoom.
    if (hasPinchZoom && details.scale > 0.0) {
      newZoom = _getZoomForScale(
        _mapZoomStart,
        details.scale + _scaleCorrector,
      );

      // Handle starting of pinch zoom.
      if (!_pinchZoomStarted && newZoom != _mapZoomStart) {
        _pinchZoomStarted = true;

        if (!_pinchMoveStarted) {
          // We want to call moveStart only once for a movement so don't call
          // it if a pinch move is already underway.
          widget.controller.moveStarted(MapEventSource.onMultiFinger);
        }
      }
    }

    // Handle pinch move.
    if (hasPinchMove) {
      newCenter = _calculatePinchZoomAndMove(details, newZoom);

      if (!_pinchMoveStarted && _lastFocalLocal != details.localFocalPoint) {
        _pinchMoveStarted = true;

        if (!_pinchZoomStarted) {
          // We want to call moveStart only once for a movement so don't call
          // it if a pinch zoom is already underway.
          widget.controller.moveStarted(MapEventSource.onMultiFinger);
        }
      }
    }

    if (_pinchZoomStarted || _pinchMoveStarted) {
      widget.controller.move(
        newCenter,
        newZoom,
        offset: Offset.zero,
        hasGesture: true,
        source: MapEventSource.onMultiFinger,
        id: null,
      );
    }
  }

  LatLng _calculatePinchZoomAndMove(
    ScaleUpdateDetails details,
    double zoomAfterPinchZoom,
  ) {
    final oldCenterPt =
        _mapCamera.project(_mapCamera.center, zoomAfterPinchZoom);
    final newFocalLatLong =
        _mapCamera.offsetToCrs(_focalStartLocal, zoomAfterPinchZoom);
    final newFocalPt = _mapCamera.project(newFocalLatLong, zoomAfterPinchZoom);
    final oldFocalPt =
        _mapCamera.project(_focalStartLatLng, zoomAfterPinchZoom);
    final zoomDifference = oldFocalPt - newFocalPt;
    final moveDifference = _rotateOffset(_focalStartLocal - _lastFocalLocal);

    final newCenterPt =
        oldCenterPt + zoomDifference + moveDifference.toCustomPoint();
    return _mapCamera.unproject(newCenterPt, zoomAfterPinchZoom);
  }

  void _handleScalePinchRotate(
    ScaleUpdateDetails details,
    double currentRotation,
  ) {
    if (!_rotationStarted && currentRotation != 0.0) {
      _rotationStarted = true;
      widget.controller.rotateStarted(MapEventSource.onMultiFinger);
    }

    if (_rotationStarted) {
      final rotationDiff = currentRotation - _lastRotation;
      final oldCenterPt = _mapCamera.project(_mapCamera.center);
      final rotationCenter =
          _mapCamera.project(_mapCamera.offsetToCrs(_lastFocalLocal));
      final vector = oldCenterPt - rotationCenter;
      final rotatedVector = vector.rotate(degToRadian(rotationDiff));
      final newCenter = rotationCenter + rotatedVector;

      widget.controller.moveAndRotate(
        _mapCamera.unproject(newCenter),
        _mapCamera.zoom,
        _mapCamera.rotation + rotationDiff,
        offset: Offset.zero,
        hasGesture: true,
        source: MapEventSource.onMultiFinger,
        id: null,
      );
    }
  }

  int? _determineMultiFingerGestureWinner(double rotationThreshold,
      double currentRotation, double scale, Offset focalOffset) {
    final int winner;
    if (InteractiveFlag.hasPinchZoom(_interactionOptions.flags) &&
        (_getZoomForScale(_mapZoomStart, scale) - _mapZoomStart).abs() >=
            _interactionOptions.pinchZoomThreshold) {
      if (_interactionOptions.debugMultiFingerGestureWinner) {
        debugPrint('Multi Finger Gesture winner: Pinch Zoom');
      }
      winner = MultiFingerGesture.pinchZoom;
    } else if (InteractiveFlag.hasRotate(_interactionOptions.flags) &&
        currentRotation.abs() >= rotationThreshold) {
      if (_interactionOptions.debugMultiFingerGestureWinner) {
        debugPrint('Multi Finger Gesture winner: Rotate');
      }
      winner = MultiFingerGesture.rotate;
    } else if (InteractiveFlag.hasPinchMove(_interactionOptions.flags) &&
        (_focalStartLocal - focalOffset).distance >=
            _interactionOptions.pinchMoveThreshold) {
      if (_interactionOptions.debugMultiFingerGestureWinner) {
        debugPrint('Multi Finger Gesture winner: Pinch Move');
      }
      winner = MultiFingerGesture.pinchMove;
    } else {
      return null;
    }

    return winner;
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

    final hasFling =
        InteractiveFlag.hasFlingAnimation(_interactionOptions.flags);

    final magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity || !hasFling) {
      if (hasFling) widget.controller.flingNotStarted(eventSource);
      return;
    }

    final direction = details.velocity.pixelsPerSecond / magnitude;
    final distance = (Offset.zero &
            Size(_mapCamera.nonRotatedSize.x, _mapCamera.nonRotatedSize.y))
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
      _mapCamera.offsetToCrs(relativePosition),
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
      _mapCamera.offsetToCrs(relativePosition),
    );
  }

  void _handleLongPress(TapPosition position) {
    _resetDoubleTapHold();

    _closeFlingAnimationController(MapEventSource.longPress);
    _closeDoubleTapController(MapEventSource.longPress);

    widget.controller.longPressed(
      MapEventSource.longPress,
      position,
      _mapCamera.offsetToCrs(position.relative!),
    );
  }

  void _handleDoubleTap(TapPosition tapPosition) {
    _resetDoubleTapHold();

    _closeFlingAnimationController(MapEventSource.doubleTap);
    _closeDoubleTapController(MapEventSource.doubleTap);

    if (InteractiveFlag.hasDoubleTapZoom(_interactionOptions.flags)) {
      final newZoom = _getZoomForScale(_mapCamera.zoom, 2);
      final newCenter = _mapCamera.focusedZoomCenter(
        tapPosition.relative!.toCustomPoint(),
        newZoom,
      );
      _startDoubleTapAnimation(newZoom, newCenter);
    }
  }

  void _startDoubleTapAnimation(double newZoom, LatLng newCenter) {
    _doubleTapZoomAnimation =
        Tween<double>(begin: _mapCamera.zoom, end: newZoom)
            .chain(CurveTween(curve: Curves.linear))
            .animate(_doubleTapController);
    _doubleTapCenterAnimation =
        LatLngTween(begin: _mapCamera.center, end: newCenter)
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

    final flags = _interactionOptions.flags;
    if (InteractiveFlag.hasPinchZoom(flags)) {
      final verticalOffset = (_focalStartLocal - details.localFocalPoint).dy;
      final newZoom = _mapZoomStart - verticalOffset / 360 * _mapCamera.zoom;

      final min = _options.minZoom ?? 0.0;
      final max = _options.maxZoom ?? double.infinity;
      final actualZoom = math.max(min, math.min(max, newZoom));

      widget.controller.move(
        _mapCamera.center,
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

    final newCenterPoint = _mapCamera.project(_mapCenterStart) +
        _flingAnimation.value.toCustomPoint().rotate(_mapCamera.rotationRad);
    final newCenter = _mapCamera.unproject(newCenterPoint);

    widget.controller.move(
      newCenter,
      _mapCamera.zoom,
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
    return _mapCamera.clampZoom(resultZoom);
  }

  Offset _rotateOffset(Offset offset) {
    final radians = _mapCamera.rotationRad;
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
