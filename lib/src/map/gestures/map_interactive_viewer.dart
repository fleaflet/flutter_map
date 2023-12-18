import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/gestures/services/base_services.dart';

class MapInteractiveViewer extends StatefulWidget {
  final ChildBuilder builder;
  final MapControllerImpl controller;

  const MapInteractiveViewer({
    super.key,
    required this.builder,
    required this.controller,
  });

  @override
  State<MapInteractiveViewer> createState() => MapInteractiveViewerState();
}

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
  DragGestureService? _drag;
  DoubleTapDragZoomGestureService? _doubleTapDragZoom;
  CtrlDragRotateGestureService? _ctrlDragRotate;

  MapCamera get _camera => widget.controller.camera;

  MapOptions get _options => widget.controller.options;

  InteractionOptions get _interactionOptions => _options.interactionOptions;

  @override
  void initState() {
    super.initState();
    widget.controller.interactiveViewerState = this;
    widget.controller.addListener(reload);

    // callback gestures for the application
    if (_options.onTap != null) {
      _tap = TapGestureService(controller: widget.controller);
    }
    if (_options.onLongPress != null) {
      _longPress = LongPressGestureService(controller: widget.controller);
    }
    if (_options.onSecondaryTap != null) {
      _secondaryTap = SecondaryTapGestureService(controller: widget.controller);
    }
    if (_options.onSecondaryLongPress != null) {
      _secondaryLongPress =
          SecondaryLongPressGestureService(controller: widget.controller);
    }
    if (_options.onTertiaryTap != null) {
      _tertiaryTap = TertiaryTapGestureService(controller: widget.controller);
    }
    if (_options.onTertiaryLongPress != null) {
      _tertiaryLongPress =
          TertiaryLongPressGestureService(controller: widget.controller);
    }
    // gestures that change the map camera
    updateGestures(null, _interactionOptions.enabledGestures);
  }

  @override
  void dispose() {
    widget.controller.removeListener(reload);
    super.dispose();
  }

  void reload() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final useDoubleTapCallback =
        _doubleTap != null || _doubleTapDragZoom != null;
    final useScaleCallback = _ctrlDragRotate != null ||
        _drag != null ||
        _doubleTapDragZoom != null ||
        _twoFingerInput != null;

    return Listener(
      onPointerDown: _options.onPointerDown == null
          ? null
          : (event) => _options.onPointerDown!.call(
                event,
                _camera.offsetToCrs(event.localPosition),
              ),
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
        // mouse scroll wheel
        if (event is PointerScrollEvent) {
          _scrollWheelZoom?.submit(event);
        }
      },
      child: GestureDetector(
        onTapDown: _tap?.setDetails,
        onTapCancel: _tap?.reset,
        onTap: _tap?.submit,

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
        onTertiaryTapUp: _tertiaryTap?.submit,

        onTertiaryLongPressStart: _tertiaryLongPress?.submit,

        // pan and scale, scale is a superset of the pan gesture
        onScaleStart: useScaleCallback
            ? (details) {
                if (_ctrlDragRotate?.keyPressed ?? false) {
                  _ctrlDragRotate!.start();
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
                if (_ctrlDragRotate?.keyPressed ?? false) {
                  _ctrlDragRotate!.update(details);
                } else if (_doubleTapDragZoom?.isActive ?? false) {
                  _doubleTapDragZoom!.update(details);
                } else if (details.pointerCount == 1) {
                  _drag?.update(details);
                } else {
                  _twoFingerInput?.update(details);
                }
              }
            : null,
        onScaleEnd: useScaleCallback
            ? (details) {
                if (_ctrlDragRotate?.keyPressed ?? false) {
                  _ctrlDragRotate!.end();
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

  /// Used by the internal map controller to update interaction gestures
  void updateGestures(EnabledGestures? oldFlags, EnabledGestures newFlags) {
    if (oldFlags == newFlags) return;
    if (newFlags.hasMultiFinger()) {
      _twoFingerInput = TwoFingerGesturesService(controller: widget.controller);
    } else {
      _twoFingerInput = null;
    }

    if (newFlags.drag) {
      _drag = DragGestureService(controller: widget.controller);
    } else {
      _drag = null;
    }

    if (newFlags.doubleTapZoomIn) {
      _doubleTap = DoubleTapGestureService(controller: widget.controller);
    } else {
      _doubleTap = null;
    }

    if (newFlags.scrollWheelZoom) {
      _scrollWheelZoom =
          ScrollWheelZoomGestureService(controller: widget.controller);
    } else {
      _scrollWheelZoom = null;
    }

    if (newFlags.ctrlDragRotate) {
      _ctrlDragRotate = CtrlDragRotateGestureService(
        controller: widget.controller,
        keys: _options.interactionOptions.ctrlRotateKeys,
      );
    } else {
      _ctrlDragRotate = null;
    }

    if (newFlags.doubleTapDragZoom) {
      _doubleTapDragZoom =
          DoubleTapDragZoomGestureService(controller: widget.controller);
    } else {
      _doubleTapDragZoom = null;
    }
  }
}

typedef ChildBuilder = Widget Function(
  BuildContext context,
  MapOptions options,
  MapCamera camera,
);
