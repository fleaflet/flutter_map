import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/gestures.dart';
import 'package:flutter_map/src/map/controller/internal.dart';

typedef ChildBuilder = Widget Function(
  BuildContext context,
  MapOptions options,
  MapCamera camera,
);

class MapInteractiveViewer extends StatefulWidget {
  final ChildBuilder builder;
  final FlutterMapInternalController controller;

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
  TapGesture? _tap;
  SecondaryTapGesture? _secondaryTap;
  LongPressGesture? _longPress;
  DoubleTapGesture? _doubleTap;
  TertiaryTapGesture? _tertiaryTap;
  TertiaryLongPressGesture? _tertiaryLongPress;
  ScrollWheelZoomGesture? _scrollWheelZoom;
  MultiInputGesture? _multiInput;
  DragGesture? _drag;

  MapCamera get _camera => widget.controller.camera;

  MapOptions get _options => widget.controller.options;

  InteractionOptions get _interactionOptions => _options.interactionOptions;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(reload);

    // callback gestures for the application
    if (_options.onTap != null) {
      _tap = TapGesture(controller: widget.controller);
    }
    if (_options.onSecondaryTap != null) {
      _secondaryTap = SecondaryTapGesture(controller: widget.controller);
    }
    if (_options.onLongPress != null) {
      _longPress = LongPressGesture(controller: widget.controller);
    }
    if (_options.onTertiaryTap != null) {
      _tertiaryTap = TertiaryTapGesture(controller: widget.controller);
    }
    if (_options.onTertiaryLongPress != null) {
      _tertiaryLongPress =
          TertiaryLongPressGesture(controller: widget.controller);
    }
    // gestures that change the map camera
    updateGestures(_interactionOptions.flags);
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
    return Listener(
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
        onSecondaryTapCancel: () => _secondaryTap?.reset(),
        onSecondaryTap: _secondaryTap?.submit,

        onDoubleTapDown: _doubleTap?.setDetails,
        onDoubleTapCancel: () => _doubleTap?.reset,
        onDoubleTap: _doubleTap?.submit,

        onTertiaryTapDown: _tertiaryTap?.setDetails,
        onTertiaryTapCancel: () => _tertiaryTap?.reset,
        onTertiaryTapUp: _tertiaryTap?.submit,

        onTertiaryLongPressStart: _tertiaryLongPress?.submit,

        // pan and scale, scale is a superset of the pan gesture
        onScaleStart: _multiInput?.start,
        onScaleUpdate: _multiInput?.update,
        onScaleEnd: _multiInput?.end,

        child: widget.builder(context, _options, _camera),
      ),
    );
  }

  /// Used by the internal map controller to update interaction gestures
  void updateGestures(int flags) {
    _multiInput = MultiInputGesture(controller: widget.controller);

    if (InteractiveFlag.hasDrag(flags)) {
      _drag = DragGesture(controller: widget.controller);
    } else {
      _drag?.end();
      _drag = null;
    }

    if (InteractiveFlag.hasDoubleTapZoom(flags)) {
      _doubleTap = DoubleTapGesture(controller: widget.controller);
    } else {
      _doubleTap = null;
    }

    if (MultiFingerGesture.hasRotate(flags)) {
      _scrollWheelZoom = ScrollWheelZoomGesture(controller: widget.controller);
    } else {
      _scrollWheelZoom = null;
    }
  }

  /// Used by the internal map controller
  void interruptAnimatedMovement(MapEventMove event) {
    // TODO implement
  }
}
