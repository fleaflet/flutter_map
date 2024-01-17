part of 'base_services.dart';

/// Service to handle the double-tap and drag gesture to let the user zoom in
/// and out with a single finger / one hand.
class DoubleTapDragZoomGestureService extends _ProgressableGestureService {
  bool isActive = false;
  Offset? _focalLocalStart;
  double? _mapZoomStart;

  DoubleTapDragZoomGestureService({required super.controller});

  /// Called when the gesture is started, stores important values.
  @override
  void start(ScaleStartDetails details) {
    super.start(details);
    _focalLocalStart = details.localFocalPoint;
    _mapZoomStart = _camera.zoom;
    controller.emitMapEvent(
      MapEventDoubleTapDragZoomStart(
        camera: _camera,
        source: MapEventSource.doubleTapHold,
      ),
    );
  }

  /// Called when the gesture receives an update, updates the [MapCamera].
  @override
  void update(ScaleUpdateDetails details) {
    if (_focalLocalStart == null || _mapZoomStart == null) return;

    final verticalOffset = (_focalLocalStart! - details.localFocalPoint).dy;
    final newZoom = _mapZoomStart! - verticalOffset / 360 * _camera.zoom;
    final min = _options.minZoom ?? 0.0;
    final max = _options.maxZoom ?? double.infinity;
    final actualZoom = math.max(min, math.min(max, newZoom));
    controller.moveRaw(
      _camera.center,
      actualZoom,
      hasGesture: true,
      source: MapEventSource.doubleTapHold,
    );
  }

  /// Called when the gesture ends, cleans up the previously stored values.
  @override
  void end(ScaleEndDetails details) {
    _mapZoomStart = null;
    _focalLocalStart = null;
    controller.emitMapEvent(
      MapEventDoubleTapDragZoomEnd(
        camera: _camera,
        source: MapEventSource.doubleTapHold,
      ),
    );
  }
}
