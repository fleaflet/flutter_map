part of 'base_services.dart';

/// A gesture with multiple inputs. This service handles the following gestures:
/// - [EnabledGestures.twoFingerMove]
/// - [EnabledGestures.twoFingerZoom]
/// - [EnabledGestures.twoFingerRotate]
class TwoFingerGesturesService extends BaseGestureService {
  MapCamera? _startCamera;
  LatLng? _startFocalLatLng;
  Offset? _startLocalFocal;

  MapCamera? _lastCamera;
  Offset? _lastLocalFocal;
  double? _lastScale;
  double? _lastRotation;

  bool _zooming = false;
  bool _moving = false;
  bool _rotating = false;

  /// Getter as shortcut to check if [EnabledGestures.twoFingerMove]
  /// is enabled.
  bool get _moveEnabled =>
      _options.interactionOptions.enabledGestures.twoFingerMove;

  /// Getter as shortcut to check if [EnabledGestures.twoFingerRotate]
  /// is enabled.
  bool get _rotateEnabled =>
      _options.interactionOptions.enabledGestures.twoFingerRotate;

  /// Getter as shortcut to check if [EnabledGestures.twoFingerZoom]
  /// is enabled.
  bool get _zoomEnabled =>
      _options.interactionOptions.enabledGestures.twoFingerZoom;

  double get _rotateThreshold =>
      _options.interactionOptions.twoFingerRotateThreshold;

  double get _moveThreshold =>
      _options.interactionOptions.twoFingerMoveThreshold;

  double get _zoomThreshold =>
      _options.interactionOptions.twoFingerZoomThreshold;

  TwoFingerGesturesService({required super.controller});

  /// Initialize gesture, called when gesture has started.
  /// Stores all values, that are required later on.
  void start(ScaleStartDetails details) {
    if (details.pointerCount < 2) return;

    _startCamera = _camera;
    _startLocalFocal = _lastLocalFocal = details.localFocalPoint;
    _startFocalLatLng = _camera.offsetToCrs(_startLocalFocal!);

    _lastScale = 1;
    _lastRotation = 0;
    _lastLocalFocal = _startLocalFocal;
    _lastCamera = _startCamera;

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

  /// Called multiple times to handle updates to the gesture.
  /// Updates the [MapCamera].
  void update(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;
    if (_lastLocalFocal == null ||
        _lastScale == null ||
        _lastRotation == null ||
        _startCamera == null ||
        _startLocalFocal == null ||
        _startFocalLatLng == null ||
        _lastCamera == null) {
      return;
    }

    double newRotation = _camera.rotation;
    if (_rotateEnabled) {
      // enable rotation if threshold is reached
      if (!_rotating && details.rotation.abs() > _rotateThreshold) {
        _rotating = true;
      }
      if (_rotating) {
        newRotation -= (_lastRotation! - details.rotation) * 80;
      }
    }

    double newZoom = _camera.zoom;
    if (_zoomEnabled) {
      // enable zooming if threshold is reached
      final scaleDiff = (_lastScale! - details.scale) * 1.5;
      const startScale = 1;
      if (!_zooming && (scaleDiff - startScale).abs() > _zoomThreshold) {
        _zooming = true;
      }
      if (_zooming) {
        final tmpZoom = details.scale == 1
            ? _startCamera!.zoom
            : _startCamera!.zoom + math.log(details.scale) / math.ln2;
        newZoom = _camera.clampZoom(tmpZoom);
      }
    }

    LatLng newCenter = _camera.center;
    if (_moveEnabled) {
      final distanceSqToStart =
          (details.localFocalPoint - _startLocalFocal!).distanceSquared;
      // Ignore twoFingerMoveThreshold if twoFingerZoomThreshold is reached.
      if (!_moving && distanceSqToStart > _moveThreshold || _zooming) {
        // Move threshold reached or zooming activated.
        _moving = true;
      }
      if (_moving) {
        math.Point<double> newCenterPt;
        if (_zooming) {
          final oldCenterPt = _camera.project(_camera.center, newZoom);
          final newFocalLatLong =
              _camera.offsetToCrs(_startLocalFocal!, newZoom);
          final newFocalPt = _camera.project(newFocalLatLong, newZoom);
          final oldFocalPt = _camera.project(_startFocalLatLng!, newZoom);
          final zoomDifference = oldFocalPt - newFocalPt;
          final moveDifference =
              _rotateOffset(_camera, _startLocalFocal! - _lastLocalFocal!);

          newCenterPt = oldCenterPt + zoomDifference + moveDifference.toPoint();
        } else {
          // simplification for no zooming
          final currentOffset = _rotateOffset(
            _camera,
            _lastLocalFocal! - details.localFocalPoint,
          );
          newCenterPt = _camera.project(_camera.center, newZoom) +
              currentOffset.toPoint();
        }
        newCenter = _camera.unproject(newCenterPt, newZoom);
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
    _lastCamera = _camera;
    _lastScale = details.scale;
    _lastLocalFocal = details.localFocalPoint;
  }

  /// gesture has ended, clean up the previously stored values.
  void end(ScaleEndDetails details) {
    if (details.pointerCount < 2) return;
    _startCamera = null;
    _startLocalFocal = null;
    _startFocalLatLng = null;

    _lastCamera = null;
    _lastScale = null;
    _lastLocalFocal = null;
    _lastRotation = null;

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
