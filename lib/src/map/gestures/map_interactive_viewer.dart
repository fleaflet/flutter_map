import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/gestures/services/base_services.dart';

/// The [MapInteractiveViewer] widget contains the [GestureDetector] and
/// [Listener] to handle gesture inputs.
/// It applies interactions (gestures/scroll/taps etc) to the
/// current [MapCamera] via the internal [controller].
class MapInteractiveViewer extends StatefulWidget {
  /// The builder callback for the child widget.
  final ChildBuilder builder;

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

/// The state for the [MapInteractiveViewer]
class MapInteractiveViewerState extends State<MapInteractiveViewer>
    with TickerProviderStateMixin {
  TapGestureService? _tap;
  LongPressGestureService? _longPress;
  SecondaryTapGestureService? _secondaryTap;
  SecondaryLongPressGestureService? _secondaryLongPress;
  TertiaryTapGestureService? _tertiaryTap;
  TertiaryLongPressGestureService? _tertiaryLongPress;
  DoubleTapGestureService? _doubleTap;
  ScrollWheelZoomGestureService? _scrollWheelZoom;
  TwoFingerGesturesService? _twoFingerInput;
  TrackpadZoomGestureService? _trackpadZoom;
  TrackpadLegacyZoomGestureService? _trackpadLegacyZoom;
  DragGestureService? _drag;
  DoubleTapDragZoomGestureService? _doubleTapDragZoom;
  KeyTriggerDragRotateGestureService? _keyTriggerDragRotate;
  KeyTriggerClickRotateGestureService? _keyTriggerClickRotate;

  MapControllerImpl get _controller => widget.controller;

  MapCamera get _camera => _controller.camera;

  MapOptions get _options => _controller.options;

  InteractionOptions get _interactionOptions => _options.interactionOptions;

  /// Initialize all services for the enabled gestures and input callbacks.
  @override
  void initState() {
    super.initState();
    _controller.interactiveViewerState = this;
    _controller.addListener(reload);

    // callback gestures for the application
    if (_options.onTap != null) {
      _tap = TapGestureService(controller: _controller);
    }
    if (_options.onLongPress != null) {
      _longPress = LongPressGestureService(controller: _controller);
    }
    if (_options.onSecondaryTap != null) {
      _secondaryTap = SecondaryTapGestureService(controller: _controller);
    }
    if (_options.onSecondaryLongPress != null) {
      _secondaryLongPress =
          SecondaryLongPressGestureService(controller: _controller);
    }
    if (_options.onTertiaryTap != null) {
      _tertiaryTap = TertiaryTapGestureService(controller: _controller);
    }
    if (_options.onTertiaryLongPress != null) {
      _tertiaryLongPress =
          TertiaryLongPressGestureService(controller: _controller);
    }
    // gestures that change the map camera
    updateGestures(null, _interactionOptions.gestures);
  }

  /// Called when the widgets gets disposed, used to clean up Stream listeners
  @override
  void dispose() {
    _controller.removeListener(reload);
    super.dispose();
  }

  /// Calls [setState] on the [MapInteractiveViewer] widget to refresh the
  /// widget.
  void reload() {
    if (mounted) setState(() {});
  }

  /// Widget build method
  @override
  Widget build(BuildContext context) {
    final useDoubleTapCallback =
        _doubleTap != null || _doubleTapDragZoom != null;
    final useScaleCallback = _keyTriggerDragRotate != null ||
        _drag != null ||
        _doubleTapDragZoom != null ||
        _twoFingerInput != null;
    final useTapCallback = _tap != null || _keyTriggerClickRotate != null;

    return Listener(
      onPointerDown: (event) {
        _controller.stopAnimationRaw();
        _options.onPointerDown?.call(
          event,
          _camera.offsetToCrs(event.localPosition),
        );
      },
      onPointerHover: _options.onPointerHover == null
          ? null
          : (event) => _options.onPointerHover!.call(
                event,
                _camera.offsetToCrs(event.localPosition),
              ),
      onPointerCancel: _options.onPointerCancel == null
          ? null
          : (event) => _options.onPointerCancel!.call(
                event,
                _camera.offsetToCrs(event.localPosition),
              ),
      onPointerUp: _options.onPointerUp == null
          ? null
          : (event) => _options.onPointerUp!.call(
                event,
                _camera.offsetToCrs(event.localPosition),
              ),
      onPointerSignal: (event) {
        switch (event) {
          case final PointerScrollEvent event:
            // mouse scroll wheel
            // `stopAnimationRaw()` will probably get moved to the service
            // to handle animated zooming with the scroll wheel but
            // we keep it here for now.
            _controller.stopAnimationRaw();
            _scrollWheelZoom?.submit(event);
            break;
          case final PointerScaleEvent event:
            // Trackpad pinch gesture, in case the pointerPanZoom event
            // callbacks can't be used and trackpad scrolling must still use
            // this old PointerScrollSignal system.
            //
            // This is the case if not enough data is
            // provided to the Flutter engine by platform APIs:
            // - On **Windows**, where trackpad gesture support is dependent on
            // the trackpad’s driver,
            // - On **Web**, where not enough data is provided by browser APIs.
            //
            // https://docs.flutter.dev/release/breaking-changes/trackpad-gestures#description-of-change
            _trackpadLegacyZoom?.submit(event);
            break;
        }
      },
      // Trackpad gestures on most platforms since flutter 3.3 use
      // these onPointerPanZoom* callbacks.
      // See https://docs.flutter.dev/release/breaking-changes/trackpad-gestures
      onPointerPanZoomStart: _trackpadZoom?.start,
      onPointerPanZoomUpdate: _trackpadZoom?.update,
      onPointerPanZoomEnd: _trackpadZoom?.end,

      child: GestureDetector(
        onTapDown: useTapCallback
            ? (details) {
                if (_keyTriggerClickRotate?.keyPressed ?? false) {
                  _keyTriggerClickRotate!.setDetails(details);
                  return;
                }
                _tap?.setDetails(details);
              }
            : null,
        onTapCancel: useTapCallback
            ? () {
                if (_keyTriggerClickRotate?.isActive ?? false) {
                  _keyTriggerClickRotate!.reset();
                  return;
                }
                _tap?.reset();
              }
            : null,
        onTap: useTapCallback
            ? () {
                if (_keyTriggerClickRotate?.keyPressed ?? false) {
                  // Normally we would wait until the tap gesture is confirmed.
                  // For this gesture however we call it directly for faster
                  // response time. (Note that `onTap` still has a small delay)
                  // This however has the trade-off that the gesture could turn
                  // out to be a double click and both gesture would fire.
                  final screenSize = MediaQuery.sizeOf(context);
                  _keyTriggerClickRotate!.submit(screenSize);
                  return;
                }
                _tap?.submit();
              }
            : null,

        onLongPressStart: _longPress?.submit,

        onSecondaryTapDown: _secondaryTap?.setDetails,
        onSecondaryTapCancel: _secondaryTap?.reset,
        onSecondaryTap: _secondaryTap?.submit,

        onSecondaryLongPressStart: _secondaryLongPress?.submit,

        onDoubleTapDown: useDoubleTapCallback
            ? (details) {
                _doubleTapDragZoom?.isActive = true;
                _doubleTap?.setDetails(details);
              }
            : null,
        onDoubleTapCancel: useDoubleTapCallback
            ? () {
                _doubleTapDragZoom?.isActive = true;
                _doubleTap?.reset();
              }
            : null,
        onDoubleTap: useDoubleTapCallback
            ? () {
                _doubleTapDragZoom?.isActive = false;
                _doubleTap?.submit();
              }
            : null,

        onTertiaryTapDown: _tertiaryTap?.setDetails,
        onTertiaryTapCancel: _tertiaryTap?.reset,
        onTertiaryTapUp:
            _tertiaryTap == null ? null : (_) => _tertiaryTap?.submit(),

        onTertiaryLongPressStart: _tertiaryLongPress?.submit,

        // pan and scale, scale is a superset of the pan gesture
        onScaleStart: useScaleCallback
            ? (details) {
                if (_keyTriggerDragRotate?.keyPressed ?? false) {
                  final screenSize = MediaQuery.sizeOf(context);
                  _keyTriggerDragRotate!.start(screenSize);
                } else if (_doubleTapDragZoom?.isActive ?? false) {
                  _doubleTapDragZoom!.start(details);
                } else if (details.pointerCount == 1) {
                  _drag?.start(details);
                } else {
                  _twoFingerInput?.start(details);
                }
              }
            : null,
        onScaleUpdate: useScaleCallback
            ? (details) {
                if (_keyTriggerDragRotate?.keyPressed ?? false) {
                  _keyTriggerDragRotate!.update(details);
                } else if (_doubleTapDragZoom?.isActive ?? false) {
                  _doubleTapDragZoom!.update(details);
                } else if (details.pointerCount == 1 && details.scale == 1) {
                  _drag?.update(details);
                } else {
                  _twoFingerInput?.update(details);
                }
              }
            : null,
        onScaleEnd: useScaleCallback
            ? (details) {
                if (_keyTriggerDragRotate?.keyPressed ?? false) {
                  _keyTriggerDragRotate!.end();
                } else if (_doubleTapDragZoom?.isActive ?? false) {
                  _doubleTapDragZoom!.isActive = false;
                  _doubleTapDragZoom!.end(details);
                } else if (_drag?.isActive ?? false) {
                  _drag?.end(details);
                } else {
                  _twoFingerInput?.end(details);
                }
              }
            : null,

        child: widget.builder(context, _options, _camera),
      ),
    );
  }

  /// Perform all required actions when the [InteractionOptions] have changed.
  /// Used by the internal map controller to update interaction gestures.
  void updateGestures(MapGestures? oldGestures, MapGestures newGestures) {
    if (oldGestures == newGestures) return;
    if (newGestures.twoFingerMove ||
        newGestures.twoFingerZoom ||
        newGestures.twoFingerRotate) {
      _twoFingerInput = TwoFingerGesturesService(controller: _controller);
    } else {
      _twoFingerInput = null;
    }

    if (newGestures.drag) {
      _drag = DragGestureService(controller: _controller);
    } else {
      _drag = null;
    }

    if (newGestures.doubleTapZoomIn) {
      _doubleTap = DoubleTapGestureService(controller: _controller);
    } else {
      _doubleTap = null;
    }

    if (newGestures.scrollWheelZoom) {
      _scrollWheelZoom = ScrollWheelZoomGestureService(controller: _controller);
    } else {
      _scrollWheelZoom = null;
    }

    if (newGestures.trackpadZoom) {
      _trackpadZoom = TrackpadZoomGestureService(controller: _controller);
      _trackpadLegacyZoom =
          TrackpadLegacyZoomGestureService(controller: _controller);
    } else {
      _trackpadZoom = null;
      _trackpadLegacyZoom = null;
    }

    if (newGestures.keyTriggerDragRotate) {
      _keyTriggerDragRotate =
          KeyTriggerDragRotateGestureService(controller: _controller);
    } else {
      _keyTriggerDragRotate = null;
    }

    if (newGestures.keyTriggerClickRotate) {
      _keyTriggerClickRotate =
          KeyTriggerClickRotateGestureService(controller: _controller);
    } else {
      _keyTriggerClickRotate = null;
    }

    if (newGestures.doubleTapDragZoom) {
      _doubleTapDragZoom =
          DoubleTapDragZoomGestureService(controller: _controller);
    } else {
      _doubleTapDragZoom = null;
    }
  }
}

/// Build method for the child widget. Provides [MapOptions] and [MapCamera]
/// as parameters.
typedef ChildBuilder = Widget Function(
  BuildContext context,
  MapOptions options,
  MapCamera camera,
);
