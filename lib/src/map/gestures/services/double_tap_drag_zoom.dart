part of 'base_services.dart';

class DoubleTapDragZoomGestureService extends BaseGestureService {
  bool isActive = false;
  Offset? _focalLocalStart;
  double? _mapZoomStart;

  DoubleTapDragZoomGestureService({required super.controller});

  void start(ScaleStartDetails details) {
    controller.stopAnimationRaw();
    _focalLocalStart = details.localFocalPoint;
    _mapZoomStart = _camera.zoom;
    controller.emitMapEvent(
      MapEventDoubleTapZoomStart(
        camera: _camera,
        source: MapEventSource.doubleTapHold,
      ),
    );
  }

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

  void end(ScaleEndDetails details) {
    _mapZoomStart = null;
    _focalLocalStart = null;
    controller.emitMapEvent(
      MapEventDoubleTapZoomEnd(
        camera: _camera,
        source: MapEventSource.doubleTapHold,
      ),
    );
  }
}
