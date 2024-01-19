part of 'base_services.dart';

/// Service that handles drag gestures performed with one pointer
/// (like a finger or cursor).
class DragGestureService extends _ProgressableGestureService {
  Offset? _lastLocalFocal;
  Offset? _focalStartLocal;

  bool get _flingEnabled =>
      _options.interactionOptions.enabledGestures.flingAnimation;

  DragGestureService({required super.controller});

  bool get isActive => _lastLocalFocal != null;

  /// Called when the gesture is started, stores important values.
  @override
  void start(ScaleStartDetails details) {
    _lastLocalFocal = details.localFocalPoint;
    _focalStartLocal = details.localFocalPoint;
    controller.emitMapEvent(
      MapEventMoveStart(
        camera: _camera,
        source: MapEventSource.dragStart,
      ),
    );
  }

  /// Called when the gesture receives an update, updates the [MapCamera].
  @override
  void update(ScaleUpdateDetails details) {
    if (_lastLocalFocal == null) return;

    final offset = _rotateOffset(
      _camera,
      _lastLocalFocal! - details.localFocalPoint,
    );
    final oldCenterPt = _camera.project(_camera.center);
    final newCenterPt = oldCenterPt + offset.toPoint();
    final newCenter = _camera.unproject(newCenterPt);

    controller.moveRaw(
      newCenter,
      _camera.zoom,
      hasGesture: true,
      source: MapEventSource.onDrag,
    );

    _lastLocalFocal = details.localFocalPoint;
  }

  /// Called when the gesture ends, cleans up the previously stored values.
  @override
  void end(ScaleEndDetails details) {
    controller.emitMapEvent(
      MapEventMoveEnd(
        camera: _camera,
        source: MapEventSource.dragEnd,
      ),
    );
    final lastLocalFocal = _lastLocalFocal!;
    final focalStartLocal = _focalStartLocal!;
    _lastLocalFocal = null;
    _focalStartLocal = null;

    if (!_flingEnabled) return;

    final magnitude = details.velocity.pixelsPerSecond.distance;

    // don't start fling if the magnitude is not high enough
    if (magnitude < 800) {
      controller.emitMapEvent(
        MapEventFlingAnimationNotStarted(
          source: MapEventSource.flingAnimationController,
          camera: _camera,
        ),
      );
      return;
    }

    final direction = details.velocity.pixelsPerSecond / magnitude;

    controller.flingAnimatedRaw(
      velocity: magnitude / 1000.0,
      direction: direction,
      begin: focalStartLocal - lastLocalFocal,
      hasGesture: true,
    );
    controller.emitMapEvent(
      MapEventFlingAnimationStart(
        source: MapEventSource.flingAnimationController,
        camera: _camera,
      ),
    );
  }
}
