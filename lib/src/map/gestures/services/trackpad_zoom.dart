part of 'base_services.dart';

/// Service to handle the trackpad (aka. touchpad) zoom gesture to zoom
/// the map in or out.
///
/// Trackpad gestures on most platforms since flutter 3.3 use
/// these onPointerPanZoom* callbacks.
/// See https://docs.flutter.dev/release/breaking-changes/trackpad-gestures
class TrackpadZoomGestureService extends _BaseGestureService {
  double _lastScale = 1;
  Offset? _startLocalFocal;
  LatLng? _startFocalLatLng;
  Offset? _lastLocalFocal;

  TrackpadZoomGestureService({required super.controller});

  double get _velocity => _options.interactionOptions.trackpadZoomVelocity;

  bool get _moveEnabled => _options.interactionOptions.gestures.drag;

  void start(PointerPanZoomStartEvent details) {
    _lastScale = 1;
    _startLocalFocal = details.localPosition;
    _startFocalLatLng = _camera.offsetToCrs(_startLocalFocal!);
    _lastLocalFocal = _startLocalFocal;
  }

  void update(PointerPanZoomUpdateEvent details) {
    if (_startFocalLatLng == null ||
        _startLocalFocal == null ||
        _lastLocalFocal == null) return;
    if (details.scale == _lastScale) return;
    final scaleFactor = (details.scale - _lastScale) * _velocity + 1;

    final tmpZoom = _camera.zoom * scaleFactor;
    final newZoom = _camera.clampZoom(tmpZoom);

    LatLng newCenter = _camera.center;
    if (_moveEnabled) {
      math.Point<double> newCenterPt;

      final oldCenterPt = _camera.project(_camera.center, newZoom);
      final newFocalLatLng = _camera.offsetToCrs(_startLocalFocal!, newZoom);
      final newFocalPt = _camera.project(newFocalLatLng, newZoom);
      final oldFocalPt = _camera.project(_startFocalLatLng!, newZoom);
      final zoomDifference = oldFocalPt - newFocalPt;
      final moveDifference =
          _rotateOffset(_camera, _startLocalFocal! - _lastLocalFocal!);

      newCenterPt = oldCenterPt + zoomDifference + moveDifference.toPoint();
      newCenter = _camera.unproject(newCenterPt, newZoom);
    }

    _lastScale = details.scale;
    _lastLocalFocal = details.localPosition;
    controller.moveRaw(
      newCenter,
      newZoom,
      hasGesture: true,
      source: MapEventSource.trackpad,
    );
  }

  void end(PointerPanZoomEndEvent details) {
    _startLocalFocal = null;
    _startFocalLatLng = null;
    _lastLocalFocal = null;
  }
}
