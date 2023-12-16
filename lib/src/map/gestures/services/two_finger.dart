part of 'base_services.dart';

/// A gesture with multiple inputs like zooming with two fingers
class TwoFingerGesturesService extends BaseGestureService {
  Offset? _startLocalFocal;
  double? _startScale;
  double? _startRotation;
  Offset? _lastLocalFocal;
  double? _lastScale;
  double? _lastRotation;
  bool _zooming = false;
  bool _moving = false;
  bool _rotating = false;

  bool get _moveEnabled =>
      _options.interactionOptions.enabledGestures.twoFingerMove;

  bool get _rotateEnabled =>
      _options.interactionOptions.enabledGestures.twoFingerRotate;

  bool get _zoomEnabled =>
      _options.interactionOptions.enabledGestures.twoFingerZoom;

  double get _rotateThreshold =>
      _options.interactionOptions.twoFingerRotateThreshold;

  double get _moveThreshold =>
      _options.interactionOptions.twoFingerMoveThreshold;

  double get _zoomThreshold =>
      _options.interactionOptions.twoFingerZoomThreshold;

  TwoFingerGesturesService({required super.controller});

  /// Initialize gesture, called when gesture has started
  void start(ScaleStartDetails details) {
    controller.stopAnimationRaw();
    if (details.pointerCount < 2) return;

    _lastLocalFocal = details.localFocalPoint;
    _lastScale = 1;
    _lastRotation = 0;
    _startLocalFocal = _lastLocalFocal;
    _startScale = _lastScale;
    _startRotation = _lastRotation;
    _rotating = false;
    _moving = false;
    _zooming = false;

    controller.emitMapEvent(
      MapEventMoveStart(
        camera: _camera,
        source: MapEventSource.multiFingerStart,
      ),
    );
  }

  /// Called multiple times to handle updates to the gesture
  void update(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;
    if (_lastLocalFocal == null ||
        _lastScale == null ||
        _lastRotation == null ||
        _startScale == null ||
        _startRotation == null ||
        _startLocalFocal == null) {
      return;
    }

    // TODO: adjust every threshold value
    double newRotation = _camera.rotation;
    if (_rotateEnabled) {
      // enable rotation if threshold is reached
      if (!_rotating &&
          (details.rotation - _startRotation!).abs() > _rotateThreshold) {
        _rotating = true;
      }
      if (_rotating) {
        newRotation -= (_lastRotation! - details.rotation) * 80;
      }
    }

    LatLng newCenter = _camera.center;
    if (_moveEnabled) {
      final offset = _rotateOffset(
        _camera,
        _lastLocalFocal! - details.localFocalPoint,
      );
      // enable moving if threshold is reached
      if (!_moving &&
          ((offset - _startLocalFocal!).distanceSquared) > _moveThreshold) {
        _moving = true;
      }
      if (_moving) {
        final oldCenterPt = _camera.project(_camera.center);
        final newCenterPt = oldCenterPt + offset.toPoint();
        newCenter = _camera.unproject(newCenterPt);
      }
    }

    double newZoom = _camera.zoom;
    if (_zoomEnabled) {
      // enable zooming if threshold is reached
      // TODO: fix bug where zooming is faster if you zoom in at the start of the gesture
      final scaleDiff = (_lastScale! - details.scale) * 1.5;
      if (!_zooming && (scaleDiff - _startScale!).abs() > _zoomThreshold) {
        _zooming = true;
      }
      if (_zooming) {
        // TODO: add support to zoom to the gesture, not the map center
        newZoom -= scaleDiff;
      }
    }

    controller.moveAndRotateRaw(
      newCenter,
      newZoom,
      newRotation,
      offset: Offset.zero,
      hasGesture: true,
      source: MapEventSource.onMultiFinger,
    );

    _lastRotation = details.rotation;
    _lastScale = details.scale;
    _lastLocalFocal = details.localFocalPoint;
  }

  /// gesture has ended, clean up
  void end(ScaleEndDetails details) {
    if (details.pointerCount < 2) return;
    _lastScale = null;
    _lastLocalFocal = null;
    _lastRotation = null;
    _startRotation = null;
    _startLocalFocal = null;
    _startScale = null;
    _rotating = false;
    _zooming = false;
    _moving = false;
    controller.emitMapEvent(
      MapEventMoveEnd(
        camera: _camera,
        source: MapEventSource.multiFingerEnd,
      ),
    );
  }
}
