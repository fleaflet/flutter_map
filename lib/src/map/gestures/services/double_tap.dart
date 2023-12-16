part of 'base_services.dart';

class DoubleTapGestureService extends DelayedGestureService {
  DoubleTapGestureService({required super.controller});

  /// A double tap gesture tap has been registered
  void submit() {
    controller.stopAnimationRaw();
    if (details == null) return;

    // start double tap animation
    final newZoom = _getZoomForScale(_camera.zoom, 2);
    final newCenter = _camera.focusedZoomCenter(
      details!.localPosition.toPoint(),
      newZoom,
    );

    controller.emitMapEvent(
      MapEventDoubleTapZoomStart(
        camera: _camera,
        source: MapEventSource.doubleTap,
      ),
    );

    controller.moveAnimatedRaw(
      newCenter,
      newZoom,
      hasGesture: true,
      source: MapEventSource.doubleTap,
      curve: Curves.fastOutSlowIn,
      duration: const Duration(milliseconds: 200),
    );

    controller.emitMapEvent(
      MapEventDoubleTapZoomEnd(
        camera: _camera,
        source: MapEventSource.doubleTap,
      ),
    );

    reset();
  }

  /// get the calculated zoom level for a given scaling, relative for the
  /// startZoomLevel
  double _getZoomForScale(double startZoom, double scale) {
    if (scale == 1) {
      return _camera.clampZoom(startZoom);
    }
    return _camera.clampZoom(startZoom + math.log(scale) / math.ln2);
  }
}
