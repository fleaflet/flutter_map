import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
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
  TapDownDetails? _tapDetails;
  TapDownDetails? _secondaryTapDetails;
  TapDownDetails? _doubleTapDetails;
  TapDownDetails? _tertiaryTapDetails;

  Offset? _lastFocalLocal;

  MapCamera get _camera => widget.controller.camera;

  MapOptions get _options => widget.controller.options;

  InteractionOptions get _interactionOptions => _options.interactionOptions;

  bool _gestureEnabled(int flag) {
    if (flag == InteractiveFlag.scrollWheelZoom &&
        // ignore: deprecated_member_use_from_same_package
        _interactionOptions.enableScrollWheel) {
      return true;
    }
    return InteractiveFlag.hasFlag(
      _options.interactionOptions.flags,
      flag,
    );
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(reload);
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
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        onTapDown: (details) => _tapDetails = details,
        onTapCancel: () => _tapDetails = null,
        onTap: _onTap,

        onLongPressStart: _onLongPressStart,

        onSecondaryTapDown: (details) => _secondaryTapDetails = details,
        onSecondaryTapCancel: () => _secondaryTapDetails = null,
        onSecondaryTap: _onSecondaryTap,

        onDoubleTapDown: (details) => _doubleTapDetails = details,
        onDoubleTapCancel: () => _doubleTapDetails = null,
        onDoubleTap: _onDoubleTap,

        onTertiaryTapDown: (details) => _tertiaryTapDetails = details,
        onTertiaryTapCancel: () => _tertiaryTapDetails = null,
        onTertiaryTapUp: _onTertiaryTapUp,

        onTertiaryLongPressStart: _onTertiaryLongPressStart,

        // pan and scale, scale is a superset of the pan gesture
        onScaleStart: _onScalePanStart,
        onScaleUpdate: _onScalePanUpdate,
        onScaleEnd: _onScalePanEnd,

        child: widget.builder(
          context,
          widget.controller.options,
          _camera,
        ),
      ),
    );
  }

  /// A tap with a primary button has occurred.
  /// This triggers when the tap gesture wins.
  void _onTap() {
    print('[MapInteractiveViewer] tap');
    if (_tapDetails == null) return;
    final details = _tapDetails!;
    _tapDetails = null;
    widget.controller.tapped(
      MapEventSource.tap,
      TapPosition(details.globalPosition, details.localPosition),
      _camera.offsetToCrs(details.localPosition),
    );
  }

  /// Called when a long press gesture with a primary button has been
  /// recognized. A pointer has remained in contact with the screen at the
  /// same location for a long period of time.
  void _onLongPressStart(LongPressStartDetails details) {
    print('[MapInteractiveViewer] long press');
    widget.controller.longPressed(
      MapEventSource.longPress,
      TapPosition(details.globalPosition, details.localPosition),
      _camera.offsetToCrs(details.localPosition),
    );
  }

  /// A tap with a secondary button has occurred.
  /// This triggers when the tap gesture wins.
  void _onSecondaryTap() {
    print('[MapInteractiveViewer] secondary tap');
    if (_secondaryTapDetails == null) return;
    final details = _secondaryTapDetails!;
    _secondaryTapDetails = null;
    widget.controller.secondaryTapped(
      MapEventSource.secondaryTap,
      TapPosition(details.globalPosition, details.localPosition),
      _camera.offsetToCrs(details.localPosition),
    );
  }

  /// A double tap gesture tap has been registered
  void _onDoubleTap() {
    print('[MapInteractiveViewer] double tap');
    if (_doubleTapDetails == null) return;
    final details = _doubleTapDetails!;
    _doubleTapDetails = null;
    if (!_gestureEnabled(InteractiveFlag.doubleTapZoom)) return;

    // start double tap animation
    //widget.controller.doubleTapZoomStarted(MapEventSource.doubleTap);
    // TODO
    final newZoom = _getZoomForScale(_camera.zoom, 2);
    final newCenter = _camera.focusedZoomCenter(
      details.localPosition.toPoint(),
      newZoom,
    );
    widget.controller.move(
      newCenter,
      newZoom,
      offset: Offset.zero,
      hasGesture: true,
      source: MapEventSource.doubleTap,
      id: null,
    );
  }

  void _onTertiaryTapUp(TapUpDetails _) {
    print('[MapInteractiveViewer] tertiary tap');
    if (_tertiaryTapDetails == null) return;
    final details = _tertiaryTapDetails!;
    _tertiaryTapDetails = null;
    // TODO
  }

  void _onTertiaryLongPressStart(LongPressStartDetails details) {
    print('[MapInteractiveViewer] tertiary long press');
    // TODO
  }

  void _onScalePanStart(ScaleStartDetails details) {
    print('[MapInteractiveViewer] scale pan start');
    if (!_gestureEnabled(InteractiveFlag.drag)) return;
    // TODO
    _lastFocalLocal = details.localFocalPoint;
    widget.controller.moveStarted(MapEventSource.dragStart);
  }

  void _onScalePanUpdate(ScaleUpdateDetails details) {
    print(
      '[MapInteractiveViewer] scale pan update, ${details.localFocalPoint}',
    );
    if (!_gestureEnabled(InteractiveFlag.drag)) return;
    // TODO

    widget.controller.dragUpdated(
      MapEventSource.onDrag,
      _rotateOffset(
        _lastFocalLocal! - details.localFocalPoint,
      ),
    );
    _lastFocalLocal = details.localFocalPoint;
  }

  void _onScalePanEnd(ScaleEndDetails details) {
    print('[MapInteractiveViewer] scale pan end');
    if (!_gestureEnabled(InteractiveFlag.drag)) return;
    // TODO
  }

  /// Handles mouse scroll events if the enableScrollWheel parameter is enabled
  void _onPointerSignal(PointerSignalEvent event) {
    print('[MapInteractiveViewer] on pointer signal');
    if (event is! PointerScrollEvent ||
        !_gestureEnabled(InteractiveFlag.scrollWheelZoom) ||
        event.scrollDelta.dy == 0) return;

    // Prevent scrolling of parent/child widgets simultaneously.
    // See [PointerSignalResolver] documentation for more information.
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      event as PointerScrollEvent;
      final minZoom = _options.minZoom ?? 0.0;
      final maxZoom = _options.maxZoom ?? double.infinity;
      final newZoom = (_camera.zoom -
              event.scrollDelta.dy * _interactionOptions.scrollWheelVelocity)
          .clamp(minZoom, maxZoom);
      // Calculate offset of mouse cursor from viewport center
      final newCenter = _camera.focusedZoomCenter(
        event.localPosition.toPoint(),
        newZoom,
      );
      widget.controller.move(
        newCenter,
        newZoom,
        offset: Offset.zero,
        hasGesture: true,
        source: MapEventSource.scrollWheel,
        id: null,
      );
    });
  }

  /// get the calculated zoom level for a given scaling, relative for the
  /// startZoomLevel
  double _getZoomForScale(double startZoom, double scale) {
    if (scale == 1) {
      return _camera.clampZoom(startZoom);
    }
    return _camera.clampZoom(startZoom + math.log(scale) / math.ln2);
  }

  /// Used by the internal map controller to update interaction gestures
  void updateGestures(
    InteractionOptions oldOptions,
    InteractionOptions newOptions,
  ) {
    print('[MapInteractiveViewer] updateGestures');
    // TODO
  }

  /// Used by the internal map controller
  void interruptAnimatedMovement(MapEventMove event) {
    print('[MapInteractiveViewer] interruptAnimatedMovement');
    // TODO
  }

  /// Return a rotated Offset
  Offset _rotateOffset(Offset offset) {
    final radians = _camera.rotationRad;
    if (radians == 0) return offset;

    final cos = math.cos(radians);
    final sin = math.sin(radians);
    final nx = (cos * offset.dx) + (sin * offset.dy);
    final ny = (cos * offset.dy) - (sin * offset.dx);

    return Offset(nx, ny);
  }
}
