part of 'base_services.dart';

/// Service to the handle scroll wheel gesture to zoom the map in or out.
class ScrollWheelZoomGestureService extends BaseGestureService {
  ScrollWheelZoomGestureService({required super.controller});

  /// Shortcut for the zoom velocity of the scroll wheel
  double get _scrollWheelVelocity =>
      _options.interactionOptions.scrollWheelVelocity;

  /// Handles mouse scroll events, called by the [Listener] of
  /// the [MapInteractiveViewer].
  void submit(PointerScrollEvent details) {
    controller.stopAnimationRaw();
    if (details.scrollDelta.dy == 0) return;

    // Prevent scrolling of parent/child widgets simultaneously.
    // See [PointerSignalResolver] documentation for more information.
    GestureBinding.instance.pointerSignalResolver.register(details, (details) {
      details as PointerScrollEvent;
      final newZoom =
          _camera.zoom - details.scrollDelta.dy * _scrollWheelVelocity;
      // Calculate offset of mouse cursor from viewport center
      final newCenter = _camera.focusedZoomCenter(
        details.localPosition.toPoint(),
        newZoom,
      );
      controller.moveRaw(
        newCenter,
        newZoom,
        hasGesture: true,
        source: MapEventSource.scrollWheel,
      );
    });
  }
}
