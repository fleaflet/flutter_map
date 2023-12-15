import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

abstract class Gesture {
  final MapControllerImpl controller;

  const Gesture({required this.controller});

  MapCamera get _camera => controller.camera;

  MapOptions get _options => controller.options;
}

abstract class DelayedGesture extends Gesture {
  TapDownDetails? details;

  DelayedGesture({required super.controller});

  void setDetails(TapDownDetails newDetails) => details = newDetails;

  void reset() => details = null;
}

class TapGesture extends DelayedGesture {
  TapGesture({required super.controller});

  /// A tap with a primary button has occurred.
  /// This triggers when the tap gesture wins.
  void submit() {
    controller.stopAnimationRaw();
    if (details == null) return;

    final point = _camera.offsetToCrs(details!.localPosition);
    _options.onTap?.call(details!, point);
    controller.emitMapEvent(
      MapEventTap(
        tapPosition: point,
        camera: _camera,
        source: MapEventSource.tap,
      ),
    );

    reset();
  }
}

class LongPressGesture extends Gesture {
  LongPressGesture({required super.controller});

  /// Called when a long press gesture with a primary button has been
  /// recognized. A pointer has remained in contact with the screen at the
  /// same location for a long period of time.
  void submit(LongPressStartDetails details) {
    controller.stopAnimationRaw();
    final position = _camera.offsetToCrs(details.localPosition);
    _options.onLongPress?.call(details, position);
    controller.emitMapEvent(
      MapEventLongPress(
        tapPosition: position,
        camera: _camera,
        source: MapEventSource.longPress,
      ),
    );
  }
}

class SecondaryLongPressGesture extends Gesture {
  SecondaryLongPressGesture({required super.controller});

  /// Called when a long press gesture with a primary button has been
  /// recognized. A pointer has remained in contact with the screen at the
  /// same location for a long period of time.
  void submit(LongPressStartDetails details) {
    controller.stopAnimationRaw();
    final position = _camera.offsetToCrs(details.localPosition);
    _options.onSecondaryLongPress?.call(details, position);
    controller.emitMapEvent(
      MapEventSecondaryLongPress(
        tapPosition: position,
        camera: _camera,
        source: MapEventSource.secondaryLongPressed,
      ),
    );
  }
}

class SecondaryTapGesture extends DelayedGesture {
  SecondaryTapGesture({required super.controller});

  /// A tap with a secondary button has occurred.
  /// This triggers when the tap gesture wins.
  void submit() {
    controller.stopAnimationRaw();
    if (details == null) return;

    final position = _camera.offsetToCrs(details!.localPosition);
    _options.onSecondaryTap?.call(details!, position);
    controller.emitMapEvent(
      MapEventSecondaryTap(
        tapPosition: position,
        camera: _camera,
        source: MapEventSource.secondaryTap,
      ),
    );

    reset();
  }
}

class DoubleTapGesture extends DelayedGesture {
  DoubleTapGesture({required super.controller});

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

class TertiaryTapGesture extends DelayedGesture {
  TertiaryTapGesture({required super.controller});

  /// A tertiary tap gesture has happen (e.g. click on the mouse scroll wheel)
  void submit(TapUpDetails _) {
    controller.stopAnimationRaw();
    if (details == null) return;

    final point = _camera.offsetToCrs(details!.localPosition);
    _options.onTertiaryTap?.call(details!, point);
    controller.emitMapEvent(
      MapEventTertiaryTap(
        tapPosition: point,
        camera: _camera,
        source: MapEventSource.tertiaryTap,
      ),
    );

    reset();
  }
}

class TertiaryLongPressGesture extends DelayedGesture {
  TertiaryLongPressGesture({required super.controller});

  /// A long press on the tertiary button has happen (e.g. click and hold on
  /// the mouse scroll wheel)
  void submit(LongPressStartDetails details) {
    controller.stopAnimationRaw();
    final point = _camera.offsetToCrs(details.localPosition);
    _options.onTertiaryLongPress?.call(details, point);
    controller.emitMapEvent(
      MapEventTertiaryLongPress(
        tapPosition: point,
        camera: _camera,
        source: MapEventSource.tertiaryLongPress,
      ),
    );

    reset();
  }
}

class ScrollWheelZoomGesture extends Gesture {
  ScrollWheelZoomGesture({required super.controller});

  /// Handles mouse scroll events
  void submit(PointerScrollEvent details) {
    controller.stopAnimationRaw();
    if (details.scrollDelta.dy == 0) return;

    // Prevent scrolling of parent/child widgets simultaneously.
    // See [PointerSignalResolver] documentation for more information.
    GestureBinding.instance.pointerSignalResolver.register(details, (details) {
      details as PointerScrollEvent;
      final minZoom = _options.minZoom ?? 0.0;
      final maxZoom = _options.maxZoom ?? double.infinity;
      final newZoom = clampDouble(
        _camera.zoom - details.scrollDelta.dy * _scrollWheelVelocity * 2,
        minZoom,
        maxZoom,
      );
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

  double get _scrollWheelVelocity =>
      _options.interactionOptions.scrollWheelVelocity;
}

/// A gesture with multiple inputs like zooming with two fingers
class TwoFingerGestures extends Gesture {
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

  TwoFingerGestures({required super.controller});

  /// Initialize gesture, called when gesture has started
  void start(ScaleStartDetails details) {
    controller.stopAnimationRaw();
    if (details.pointerCount < 2) return;

    _lastLocalFocal = details.localFocalPoint;
    _lastScale = 1;
    _lastRotation = 0;
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
        _lastRotation == null) {
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
      if (!_zooming && details.scale.abs() > _zoomThreshold) {
        _zooming = true;
      }
      if (_zooming) {
        newZoom -= (_lastScale! - details.scale) * 2.2;
      }
    }

    LatLng newCenter = _camera.center;
    if (_moveEnabled) {
      final offset = _rotateOffset(
        _camera,
        _lastLocalFocal! - details.localFocalPoint,
      );
      // enable moving if threshold is reached
      if (!_moving && offset.distanceSquared > _moveThreshold) {
        _moving = true;
      }
      if (_moving) {
        final oldCenterPt = _camera.project(_camera.center);
        final newCenterPt = oldCenterPt + offset.toPoint();
        newCenter = _camera.unproject(newCenterPt);
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

class DragGesture extends Gesture {
  Offset? _lastLocalFocal;
  Offset? _focalStartLocal;

  bool get _flingEnabled =>
      _options.interactionOptions.enabledGestures.flingAnimation;

  DragGesture({required super.controller});

  bool get isActive => _lastLocalFocal != null;

  void start(ScaleStartDetails details) {
    controller.stopAnimationRaw();
    _lastLocalFocal = details.localFocalPoint;
    _focalStartLocal = details.localFocalPoint;
    controller.emitMapEvent(
      MapEventMoveStart(
        camera: _camera,
        source: MapEventSource.dragStart,
      ),
    );
  }

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

class CtrlDragRotateGesture extends Gesture {
  bool isActive = false;
  final List<LogicalKeyboardKey> keys;

  CtrlDragRotateGesture({
    required super.controller,
    required this.keys,
  });

  void start() {
    controller.stopAnimationRaw();
    controller.emitMapEvent(
      MapEventRotateStart(
        camera: _camera,
        source: MapEventSource.ctrlDragRotateStart,
      ),
    );
  }

  void update(ScaleUpdateDetails details) {
    controller.rotateRaw(
      _camera.rotation - (details.focalPointDelta.dy * 0.5),
      hasGesture: true,
      source: MapEventSource.ctrlDragRotate,
    );
  }

  void end() {
    controller.emitMapEvent(
      MapEventRotateEnd(
        camera: _camera,
        source: MapEventSource.ctrlDragRotateEnd,
      ),
    );
  }

  bool get keyPressed => RawKeyboard.instance.keysPressed
      .where((key) => keys.contains(key))
      .isNotEmpty;
}

class DoubleTapDragZoomGesture extends Gesture {
  bool isActive = false;
  Offset? _focalLocalStart;
  double? _mapZoomStart;

  DoubleTapDragZoomGesture({required super.controller});

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

/// Return a rotated Offset
Offset _rotateOffset(MapCamera camera, Offset offset) {
  final radians = camera.rotationRad;
  if (radians == 0) return offset;

  final cos = math.cos(radians);
  final sin = math.sin(radians);
  final nx = (cos * offset.dx) + (sin * offset.dy);
  final ny = (cos * offset.dy) - (sin * offset.dx);

  return Offset(nx, ny);
}
