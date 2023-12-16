part of 'base_services.dart';

class ScrollWheelZoomGestureService extends BaseGestureService {
  ScrollWheelZoomGestureService({required super.controller});

  double get _scrollWheelVelocity =>
      _options.interactionOptions.scrollWheelVelocity;

  /// Handles mouse scroll events
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
