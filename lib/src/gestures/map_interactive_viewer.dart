import 'dart:async';
import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart';

/// The method signature of the builder.
typedef InteractiveViewerBuilder = Widget Function(
  BuildContext context,
  MapOptions options,
  MapCamera camera,
);

/// Applies interactions (gestures/scroll/taps etc) to the current [MapCamera]
/// via the internal [controller].
class MapInteractiveViewer extends StatefulWidget {
  /// The [InteractiveViewerBuilder]
  final InteractiveViewerBuilder builder;

  /// Reference to the [MapControllerImpl].
  final MapControllerImpl controller;

  /// Create a new [MapInteractiveViewer] instance.
  const MapInteractiveViewer({
    super.key,
    required this.builder,
    required this.controller,
  });

  @override
  State<MapInteractiveViewer> createState() => MapInteractiveViewerState();
}

/// The widget state for the [MapInteractiveViewer].
class MapInteractiveViewerState extends State<MapInteractiveViewer>
    with TickerProviderStateMixin {
  static const int _kMinFlingVelocity = 800;
  static const _kDoubleTapZoomDuration = 200;

  /// The maximum delay between to taps to be counted as a double tap.
  static const doubleTapDelay = Duration(milliseconds: 250);

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

  /// Helps to reset ScaleUpdateDetails.scale back to 1.0 when a multi finger
  /// gesture wins
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

  // 'ckr' = cursor/keyboard rotation
  final _ckrTriggered = ValueNotifier(false);
  double _ckrClickDegrees = 0;
  double _ckrInitialDegrees = 0;

  int _tapUpCounter = 0;
  Timer? _doubleTapHoldMaxDelay;

  late final FocusNode _keyboardListenerFocusNode;
  int _keyboardPanEventCounter = 0;
  int _keyboardRotateEventCounter = 0;
  int _keyboardZoomEventCounter = 0;
  final _keyboardPanKeyDownSet = <PhysicalKeyboardKey>{};

  MapCamera get _camera => widget.controller.camera;

  MapOptions get _options => widget.controller.options;

  InteractionOptions get _interactionOptions => _options.interactionOptions;

  @override
  void initState() {
    super.initState();
    widget.controller.interactiveViewerState = this;
    widget.controller.addListener(onMapStateChange);
    _flingController
      ..addListener(_handleFlingAnimation)
      ..addStatusListener(_flingAnimationStatusListener);
    _doubleTapController
      ..addListener(_handleDoubleTapZoomAnimation)
      ..addStatusListener(_doubleTapZoomStatusListener);

    ServicesBinding.instance.keyboard
        .addHandler(cursorKeyboardRotationTriggerHandler);

    _keyboardListenerFocusNode =
        _interactionOptions.keyboardOptions.focusNode ??
            FocusNode(debugLabel: 'FlutterMap');
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
    widget.controller.removeListener(onMapStateChange);
    _flingController.dispose();
    _doubleTapController.dispose();

    _ckrTriggered.dispose();
    ServicesBinding.instance.keyboard
        .removeHandler(cursorKeyboardRotationTriggerHandler);

    _keyboardListenerFocusNode.dispose();

    super.dispose();
  }

  /// Rebuilds the map widget
  void onMapStateChange() => setState(() {});

  /// Handles key down events to detect if one of the trigger keys got pressed.
  bool cursorKeyboardRotationTriggerHandler(KeyEvent event) {
    _ckrTriggered.value = (event is KeyRepeatEvent || event is KeyDownEvent) &&
        (_interactionOptions.cursorKeyboardRotationOptions.isKeyTrigger ??
            CursorKeyboardRotationOptions
                .defaultTriggerKeys.contains)(event.logicalKey);
    return false;
  }

  /// Perform all required actions when the [InteractionOptions] have changed.
  void updateGestures(
    InteractionOptions oldOptions,
    InteractionOptions newOptions,
  ) {
    final newHasDrag = InteractiveFlag.hasDrag(newOptions.flags);
    if (newHasDrag != InteractiveFlag.hasDrag(oldOptions.flags)) {
      _gestures = _createGestures(dragEnabled: newHasDrag);
    }

    if (!InteractiveFlag.hasFlingAnimation(newOptions.flags)) {
      _closeFlingAnimationController(MapEventSource.interactiveFlagsChanged);
    }
    if (InteractiveFlag.hasDoubleTapZoom(newOptions.flags)) {
      _closeDoubleTapController(MapEventSource.interactiveFlagsChanged);
    }

    final gestures = _getMultiFingerGestureFlags(newOptions);

    if (_rotationStarted &&
        !InteractiveFlag.hasRotate(newOptions.flags) &&
        !MultiFingerGesture.hasRotate(gestures)) {
      _rotationStarted = false;

      if (_gestureWinner == MultiFingerGesture.rotate) {
        _gestureWinner = MultiFingerGesture.none;
      }

      widget.controller.rotateEnded(MapEventSource.interactiveFlagsChanged);
    }

    var emitMapEventMoveEnd = false;

    if (_pinchZoomStarted &&
        !InteractiveFlag.hasPinchZoom(newOptions.flags) &&
        !MultiFingerGesture.hasPinchZoom(gestures)) {
      _pinchZoomStarted = false;
      emitMapEventMoveEnd = true;

      if (_gestureWinner == MultiFingerGesture.pinchZoom) {
        _gestureWinner = MultiFingerGesture.none;
      }
    }

    if (_pinchMoveStarted &&
        !InteractiveFlag.hasPinchMove(newOptions.flags) &&
        !MultiFingerGesture.hasPinchMove(gestures)) {
      _pinchMoveStarted = false;
      emitMapEventMoveEnd = true;

      if (_gestureWinner == MultiFingerGesture.pinchMove) {
        _gestureWinner = MultiFingerGesture.none;
      }
    }

    if (_dragStarted && !newHasDrag) {
      _dragStarted = false;
      emitMapEventMoveEnd = true;
    }

    if (emitMapEventMoveEnd) {
      widget.controller.moveEnded(MapEventSource.interactiveFlagsChanged);
    }

    // No way to detect whether the [CursorKeyboardRotationOptions.isKeyTrigger]s
    // are equal, so assume they aren't
    ServicesBinding.instance.keyboard
        .removeHandler(cursorKeyboardRotationTriggerHandler);
    ServicesBinding.instance.keyboard
        .addHandler(cursorKeyboardRotationTriggerHandler);
  }

  Map<Type, GestureRecognizerFactory> _createGestures({
    required bool dragEnabled,
  }) {
    final gestureSettings = MediaQuery.gestureSettingsOf(context);
    return <Type, GestureRecognizerFactory>{
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(debugOwner: this),
        (recognizer) {
          recognizer
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
        (recognizer) {
          recognizer.onLongPress = _positionedTapController.onLongPress;
        },
      ),
      if (dragEnabled)
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
          () => VerticalDragGestureRecognizer(debugOwner: this),
          (recognizer) {
            recognizer
              ..gestureSettings = gestureSettings
              ..team ??= _gestureArenaTeam
              ..onUpdate = (details) {
                // Absorbing vertical drags
              };
          },
        ),
      if (dragEnabled)
        HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                HorizontalDragGestureRecognizer>(
            () => HorizontalDragGestureRecognizer(debugOwner: this),
            (recognizer) {
          recognizer
            ..gestureSettings = gestureSettings
            ..team ??= _gestureArenaTeam
            ..onUpdate = (details) {
              // Absorbing horizontal drags
            };
        }),
      ScaleGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
        () => ScaleGestureRecognizer(debugOwner: this),
        (recognizer) {
          recognizer
            ..onStart = _handleScaleStart
            ..onUpdate = _handleScaleUpdate
            ..onEnd = _handleScaleEnd
            ..team ??= _gestureArenaTeam;
          _gestureArenaTeam.captain = recognizer;
        },
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      debugLabel: 'FlutterMap',
      autofocus: _interactionOptions.keyboardOptions.autofocus,
      focusNode: _keyboardListenerFocusNode,
      onKeyEvent: _onKeyEvent,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        onPointerHover: _onPointerHover,
        onPointerMove: _onPointerMove,
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
      ),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode _, KeyEvent evt) {
    late final arrowKeysGate =
        _options.interactionOptions.keyboardOptions.enableArrowKeysPanning
            ? (evt.logicalKey != LogicalKeyboardKey.arrowLeft &&
                evt.logicalKey != LogicalKeyboardKey.arrowRight &&
                evt.logicalKey != LogicalKeyboardKey.arrowUp &&
                evt.logicalKey != LogicalKeyboardKey.arrowDown)
            : true;
    late final wasdKeysGate =
        _options.interactionOptions.keyboardOptions.enableWASDPanning
            ? (evt.logicalKey != LogicalKeyboardKey.keyW &&
                evt.logicalKey != LogicalKeyboardKey.keyA &&
                evt.logicalKey != LogicalKeyboardKey.keyS &&
                evt.logicalKey != LogicalKeyboardKey.keyD)
            : true;
    late final qeKeysGate =
        _options.interactionOptions.keyboardOptions.enableQERotating
            ? (evt.logicalKey != LogicalKeyboardKey.keyQ &&
                evt.logicalKey != LogicalKeyboardKey.keyE)
            : true;
    late final rfKeysGate =
        _options.interactionOptions.keyboardOptions.enableRFZooming
            ? (evt.logicalKey != LogicalKeyboardKey.keyR &&
                evt.logicalKey != LogicalKeyboardKey.keyF)
            : true;

    if (arrowKeysGate && wasdKeysGate && qeKeysGate && rfKeysGate) {
      return KeyEventResult.ignored;
    }

    late final arrowKeys =
        _options.interactionOptions.keyboardOptions.enableArrowKeysPanning &&
            (evt.physicalKey == PhysicalKeyboardKey.arrowLeft ||
                evt.physicalKey == PhysicalKeyboardKey.arrowRight ||
                evt.physicalKey == PhysicalKeyboardKey.arrowUp ||
                evt.physicalKey == PhysicalKeyboardKey.arrowDown);
    late final wasdKeys =
        _options.interactionOptions.keyboardOptions.enableWASDPanning &&
            (evt.physicalKey == PhysicalKeyboardKey.keyW ||
                evt.physicalKey == PhysicalKeyboardKey.keyA ||
                evt.physicalKey == PhysicalKeyboardKey.keyS ||
                evt.physicalKey == PhysicalKeyboardKey.keyD);
    late final qeKeys =
        _options.interactionOptions.keyboardOptions.enableQERotating &&
            (evt.physicalKey == PhysicalKeyboardKey.keyQ ||
                evt.physicalKey == PhysicalKeyboardKey.keyE);
    late final rfKeys =
        _options.interactionOptions.keyboardOptions.enableRFZooming &&
            (evt.physicalKey == PhysicalKeyboardKey.keyR ||
                evt.physicalKey == PhysicalKeyboardKey.keyF);

    if (evt is KeyDownEvent) {
      if (arrowKeys || wasdKeys) {
        if (_keyboardPanKeyDownSet.isEmpty) {
          _keyboardPanEventCounter = 0;
          _closeFlingAnimationController(MapEventSource.keyboard);
          _closeDoubleTapController(MapEventSource.keyboard);
        }
        _keyboardPanKeyDownSet.add(evt.physicalKey);
      } else if (qeKeys) {
        _keyboardRotateEventCounter = 0;
        _closeFlingAnimationController(MapEventSource.keyboard);
        _closeDoubleTapController(MapEventSource.keyboard);
      } else if (rfKeys) {
        _keyboardZoomEventCounter = 0;
        _closeFlingAnimationController(MapEventSource.keyboard);
        _closeDoubleTapController(MapEventSource.keyboard);
      } else {
        return KeyEventResult.skipRemainingHandlers;
      }
    }
    if (evt is KeyUpEvent) {
      if (arrowKeys || wasdKeys) {
        _keyboardPanKeyDownSet.remove(evt.physicalKey);
      }
      return KeyEventResult.skipRemainingHandlers;
    }

    if (arrowKeys || wasdKeys) _keyboardPanEventCounter++;
    if (qeKeys) _keyboardRotateEventCounter++;
    if (rfKeys) _keyboardZoomEventCounter++;

    final panSpeed = _options
            .interactionOptions.keyboardOptions.panSpeedCalculator
            ?.call(_keyboardPanEventCounter) ??
        KeyboardOptions.defaultPanSpeedCalculator(_keyboardPanEventCounter);
    var newCenter = _camera.latLngToScreenPoint(_camera.center);
    for (final key in _keyboardPanKeyDownSet) {
      newCenter = newCenter +
          switch (key) {
            PhysicalKeyboardKey.arrowLeft ||
            PhysicalKeyboardKey.keyA =>
              Point(-panSpeed, 0),
            PhysicalKeyboardKey.arrowRight ||
            PhysicalKeyboardKey.keyD =>
              Point(panSpeed, 0),
            PhysicalKeyboardKey.arrowUp ||
            PhysicalKeyboardKey.keyW =>
              Point(0, -panSpeed),
            PhysicalKeyboardKey.arrowDown ||
            PhysicalKeyboardKey.keyS =>
              Point(0, panSpeed),
            _ => throw StateError(
                '`_keyboardPanKeyDownSet` should only contain arrow & WASD keys',
              ),
          };
    }

    final rotateSpeed = _options
            .interactionOptions.keyboardOptions.rotateSpeedCalculator
            ?.call(_keyboardRotateEventCounter) ??
        KeyboardOptions.defaultRotateSpeedCalculator(
            _keyboardRotateEventCounter);
    var newRotation = _camera.rotation;
    if (qeKeys) {
      if (evt.physicalKey == PhysicalKeyboardKey.keyQ) {
        newRotation -= rotateSpeed;
      }
      if (evt.physicalKey == PhysicalKeyboardKey.keyE) {
        newRotation += rotateSpeed;
      }
    }

    final zoomSpeed = _options
            .interactionOptions.keyboardOptions.zoomSpeedCalculator
            ?.call(_keyboardZoomEventCounter) ??
        KeyboardOptions.defaultZoomSpeedCalculator(_keyboardZoomEventCounter);
    var newZoom = _camera.zoom;
    if (rfKeys) {
      if (evt.physicalKey == PhysicalKeyboardKey.keyR) {
        newZoom += zoomSpeed;
      }
      if (evt.physicalKey == PhysicalKeyboardKey.keyF) {
        newZoom -= zoomSpeed;
      }
    }

    widget.controller.moveAndRotateRaw(
      _camera.pointToLatLng(newCenter),
      newZoom,
      newRotation % 360,
      offset: Offset.zero,
      hasGesture: true,
      source: MapEventSource.keyboard,
    );

    return KeyEventResult.handled;
  }

  void _onPointerDown(PointerDownEvent event) {
    ++_pointerCounter;

    if (_ckrTriggered.value) {
      _ckrInitialDegrees = _camera.rotation;
      _ckrClickDegrees = getCursorRotationDegrees(event.localPosition);
      widget.controller.rotateStarted(MapEventSource.cursorKeyboardRotation);
    }

    if (_options.onPointerDown != null) {
      final latlng = _camera.offsetToCrs(event.localPosition);
      _options.onPointerDown!(event, latlng);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    --_pointerCounter;

    if (_interactionOptions.cursorKeyboardRotationOptions.setNorthOnClick &&
        _ckrTriggered.value &&
        _ckrInitialDegrees == _camera.rotation) {
      widget.controller.rotateRaw(
        getCursorRotationDegrees(event.localPosition),
        hasGesture: true,
        source: MapEventSource.cursorKeyboardRotation,
      );
    }

    if (_options.onPointerUp != null) {
      final latlng = _camera.offsetToCrs(event.localPosition);
      _options.onPointerUp!(event, latlng);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    --_pointerCounter;

    if (_options.onPointerCancel != null) {
      final latlng = _camera.offsetToCrs(event.localPosition);
      _options.onPointerCancel!(event, latlng);
    }
  }

  void _onPointerHover(PointerHoverEvent event) {
    if (_options.onPointerHover != null) {
      final latlng = _camera.offsetToCrs(event.localPosition);
      _options.onPointerHover!(event, latlng);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_ckrTriggered.value) return;

    final baseSetNorth =
        getCursorRotationDegrees(event.localPosition) - _ckrClickDegrees;

    widget.controller.rotateRaw(
      _interactionOptions.cursorKeyboardRotationOptions.behaviour ==
              CursorRotationBehaviour.setNorth
          ? baseSetNorth
          : (_ckrInitialDegrees + baseSetNorth) % 360,
      hasGesture: true,
      source: MapEventSource.cursorKeyboardRotation,
    );

    if (_interactionOptions.cursorKeyboardRotationOptions.behaviour ==
        CursorRotationBehaviour.setNorth) _ckrClickDegrees = 0;
  }

  void _onPointerSignal(PointerSignalEvent pointerSignal) {
    // Handle mouse scroll events if the enableScrollWheel parameter is enabled
    if (pointerSignal is PointerScrollEvent &&
        InteractiveFlag.hasScrollWheelZoom(_interactionOptions.flags) &&
        pointerSignal.scrollDelta.dy != 0) {
      // Prevent scrolling of parent/child widgets simultaneously. See
      // [PointerSignalResolver] documentation for more information.
      GestureBinding.instance.pointerSignalResolver.register(
        pointerSignal,
        (pointerSignal) {
          pointerSignal as PointerScrollEvent;
          final minZoom = _options.minZoom ?? 0.0;
          final maxZoom = _options.maxZoom ?? double.infinity;
          final newZoom = (_camera.zoom -
                  pointerSignal.scrollDelta.dy *
                      _interactionOptions.scrollWheelVelocity)
              .clamp(minZoom, maxZoom);
          // Calculate offset of mouse cursor from viewport center
          final newCenter = _camera.focusedZoomCenter(
            pointerSignal.localPosition.toPoint(),
            newZoom,
          );
          widget.controller.moveRaw(
            newCenter,
            newZoom,
            hasGesture: true,
            source: MapEventSource.scrollWheel,
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

  /// Thanks to https://stackoverflow.com/questions/48916517/javascript-click-and-drag-to-rotate
  double getCursorRotationDegrees(Offset offset) {
    const correctionTerm = 180; // North = cursor

    final size = MediaQuery.sizeOf(context);
    return (-math.atan2(
                offset.dx - size.width / 2, offset.dy - size.height / 2) *
            (180 / math.pi)) +
        correctionTerm;
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

    _mapZoomStart = _camera.zoom;
    _mapCenterStart = _camera.center;
    _focalStartLocal = _lastFocalLocal = details.localFocalPoint;
    _focalStartLatLng = _camera.offsetToCrs(_focalStartLocal);

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

    final currentRotation = details.rotation * radians2Degrees;
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
    if (_ckrTriggered.value) return;

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
    var newCenter = _camera.center;
    var newZoom = _camera.zoom;

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
      widget.controller.moveRaw(
        newCenter,
        newZoom,
        hasGesture: true,
        source: MapEventSource.onMultiFinger,
      );
    }
  }

  LatLng _calculatePinchZoomAndMove(
    ScaleUpdateDetails details,
    double zoomAfterPinchZoom,
  ) {
    final oldCenterPt = _camera.project(_camera.center, zoomAfterPinchZoom);
    final newFocalLatLong =
        _camera.offsetToCrs(_focalStartLocal, zoomAfterPinchZoom);
    final newFocalPt = _camera.project(newFocalLatLong, zoomAfterPinchZoom);
    final oldFocalPt = _camera.project(_focalStartLatLng, zoomAfterPinchZoom);
    final zoomDifference = oldFocalPt - newFocalPt;
    final moveDifference = _rotateOffset(_focalStartLocal - _lastFocalLocal);

    final newCenterPt = oldCenterPt + zoomDifference + moveDifference.toPoint();
    return _camera.unproject(newCenterPt, zoomAfterPinchZoom);
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
      final oldCenterPt = _camera.project(_camera.center);
      final rotationCenter =
          _camera.project(_camera.offsetToCrs(_lastFocalLocal));
      final vector = oldCenterPt - rotationCenter;
      final rotatedVector = vector.rotate(degrees2Radians * rotationDiff);
      final newCenter = rotationCenter + rotatedVector;

      widget.controller.moveAndRotateRaw(
        _camera.unproject(newCenter),
        _camera.zoom,
        _camera.rotation + rotationDiff,
        offset: Offset.zero,
        hasGesture: true,
        source: MapEventSource.onMultiFinger,
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

    // Prevent pan fling if rotation via keyboard/pointer is in progress
    if (_ckrTriggered.value) return;

    final hasFling =
        InteractiveFlag.hasFlingAnimation(_interactionOptions.flags);

    final magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity || !hasFling) {
      if (hasFling) widget.controller.flingNotStarted(eventSource);
      return;
    }

    final direction = details.velocity.pixelsPerSecond / magnitude;
    final distance =
        (Offset.zero & Size(_camera.nonRotatedSize.x, _camera.nonRotatedSize.y))
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
    if (_ckrTriggered.value) return;

    _closeFlingAnimationController(MapEventSource.tap);
    _closeDoubleTapController(MapEventSource.tap);

    final relativePosition = position.relative;
    if (relativePosition == null) return;

    widget.controller.tapped(
      MapEventSource.tap,
      position,
      _camera.offsetToCrs(relativePosition),
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
      _camera.offsetToCrs(relativePosition),
    );
  }

  void _handleLongPress(TapPosition position) {
    if (_ckrTriggered.value) return;

    _resetDoubleTapHold();

    _closeFlingAnimationController(MapEventSource.longPress);
    _closeDoubleTapController(MapEventSource.longPress);

    widget.controller.longPressed(
      MapEventSource.longPress,
      position,
      _camera.offsetToCrs(position.relative!),
    );
  }

  void _handleDoubleTap(TapPosition tapPosition) {
    _resetDoubleTapHold();

    _closeFlingAnimationController(MapEventSource.doubleTap);
    _closeDoubleTapController(MapEventSource.doubleTap);

    if (InteractiveFlag.hasDoubleTapZoom(_interactionOptions.flags)) {
      final newZoom = _getZoomForScale(_camera.zoom, 2);
      final newCenter = _camera.focusedZoomCenter(
        tapPosition.relative!.toPoint(),
        newZoom,
      );
      _startDoubleTapAnimation(newZoom, newCenter);
    }
  }

  void _startDoubleTapAnimation(double newZoom, LatLng newCenter) {
    _doubleTapZoomAnimation = Tween<double>(begin: _camera.zoom, end: newZoom)
        .chain(CurveTween(curve: Curves.linear))
        .animate(_doubleTapController);
    _doubleTapCenterAnimation =
        LatLngTween(begin: _camera.center, end: newCenter)
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
    widget.controller.moveRaw(
      _doubleTapCenterAnimation.value,
      _doubleTapZoomAnimation.value,
      hasGesture: true,
      source: MapEventSource.doubleTapZoomAnimationController,
    );
  }

  void _handleOnTapUp(TapUpDetails details) {
    _doubleTapHoldMaxDelay?.cancel();

    if (++_tapUpCounter == 1) {
      _doubleTapHoldMaxDelay = Timer(doubleTapDelay, _resetDoubleTapHold);
    }
  }

  void _handleDoubleTapHold(ScaleUpdateDetails details) {
    _doubleTapHoldMaxDelay?.cancel();

    final flags = _interactionOptions.flags;
    if (InteractiveFlag.hasDoubleTapDragZoom(flags)) {
      final verticalOffset = (_focalStartLocal - details.localFocalPoint).dy;
      final newZoom = _mapZoomStart - verticalOffset / 360 * _camera.zoom;

      final min = _options.minZoom ?? 0.0;
      final max = _options.maxZoom ?? double.infinity;
      final actualZoom = math.max(min, math.min(max, newZoom));

      widget.controller.moveRaw(
        _camera.center,
        actualZoom,
        hasGesture: true,
        source: MapEventSource.doubleTapHold,
      );
    }
  }

  void _handleFlingAnimation() {
    if (!_flingAnimationStarted) {
      _flingAnimationStarted = true;
      widget.controller.flingStarted(MapEventSource.flingAnimationController);
      _startListeningForAnimationInterruptions();
    }

    final newCenterPoint = _camera.project(_mapCenterStart) +
        _flingAnimation.value.toPoint().rotate(_camera.rotationRad);
    final LatLng newCenter;
    if (!_camera.crs.replicatesWorldLongitude) {
      newCenter = _camera.unproject(newCenterPoint);
    } else {
      final math.Point<double> bestCenterPoint;
      final double worldSize = _camera.crs.scale(_camera.zoom);
      if (newCenterPoint.x > worldSize) {
        bestCenterPoint =
            math.Point(newCenterPoint.x - worldSize, newCenterPoint.y);
      } else if (newCenterPoint.x < 0) {
        bestCenterPoint =
            math.Point(newCenterPoint.x + worldSize, newCenterPoint.y);
      } else {
        bestCenterPoint = newCenterPoint;
      }
      newCenter = _camera.unproject(bestCenterPoint);
    }

    widget.controller.moveRaw(
      newCenter,
      _camera.zoom,
      hasGesture: true,
      source: MapEventSource.flingAnimationController,
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

  ///
  void _startListeningForAnimationInterruptions() {
    _isListeningForInterruptions = true;
  }

  void _stopListeningForAnimationInterruptions() {
    _isListeningForInterruptions = false;
  }

  /// Cancel every ongoing animated map movements.
  void interruptAnimatedMovement(MapEvent event) {
    if (_isListeningForInterruptions) {
      _closeDoubleTapController(event.source);
      _closeFlingAnimationController(event.source);
    }
  }

  double _getZoomForScale(double startZoom, double scale) {
    final resultZoom =
        scale == 1.0 ? startZoom : startZoom + math.log(scale) / math.ln2;
    return _camera.clampZoom(resultZoom);
  }

  Offset _rotateOffset(Offset offset) {
    final radians = _camera.rotationRad;
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
