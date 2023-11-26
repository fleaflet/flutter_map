import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/controller/internal_map_controller.dart';

abstract class Gesture {
  final InternalMapController controller;

  Gesture({required this.controller});

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
    if (details == null) return;

    // start double tap animation
    // TODO animate movement
    //controller.doubleTapZoomStarted(MapEventSource.doubleTap);
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

    controller.move(
      newCenter,
      newZoom,
      offset: Offset.zero,
      hasGesture: true,
      source: MapEventSource.doubleTap,
      id: null,
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
    if (details.scrollDelta.dy == 0) return;

    // Prevent scrolling of parent/child widgets simultaneously.
    // See [PointerSignalResolver] documentation for more information.
    GestureBinding.instance.pointerSignalResolver.register(details, (details) {
      details as PointerScrollEvent;
      final minZoom = _options.minZoom ?? 0.0;
      final maxZoom = _options.maxZoom ?? double.infinity;
      final velocity = _options.interactionOptions.scrollWheelVelocity;
      final newZoom = (_camera.zoom - details.scrollDelta.dy * velocity)
          .clamp(minZoom, maxZoom);
      // Calculate offset of mouse cursor from viewport center
      final newCenter = _camera.focusedZoomCenter(
        details.localPosition.toPoint(),
        newZoom,
      );
      controller.move(
        newCenter,
        newZoom,
        offset: Offset.zero,
        hasGesture: true,
        source: MapEventSource.scrollWheel,
        id: null,
      );
    });
  }
}

/// A gesture with multiple inputs like zooming with two fingers
class TwoFingerGestures extends Gesture {
  final bool moveEnabled;
  final bool rotateEnabled;
  final bool zoomEnabled;
  Offset? _lastLocalFocal;
  double? _lastScale;
  double? _lastRotation;

  TwoFingerGestures({
    required this.moveEnabled,
    required this.rotateEnabled,
    required this.zoomEnabled,
    required super.controller,
  });

  /// Initialize gesture, called when gesture has started
  void start(ScaleStartDetails details) {
    _lastLocalFocal = details.localFocalPoint;
    _lastScale = 1;
    _lastRotation = 0;
    controller.emitMapEvent(
      MapEventMoveStart(
        camera: _camera,
        source: MapEventSource.multiFingerStart,
      ),
    );
  }

  /// Called multiple times to handle updates to the gesture
  void update(ScaleUpdateDetails details) {
    if (_lastLocalFocal == null ||
        _lastScale == null ||
        _lastRotation == null) {
      return;
    }

    // TODO implement
    double newRotation = _camera.rotation;
    if (rotateEnabled) {
      newRotation -= (_lastRotation! - details.rotation) * 80;
    }

    double newZoom = _camera.zoom;
    if (zoomEnabled) {
      newZoom -= (_lastScale! - details.scale) * 2.2;
    }

    final offset = _rotateOffset(_lastLocalFocal! - details.localFocalPoint);
    final oldCenterPt = _camera.project(_camera.center);
    final newCenterPt = oldCenterPt + offset.toPoint();
    final newCenter = _camera.unproject(newCenterPt);

    controller.moveAndRotate(
      newCenter,
      newZoom,
      newRotation,
      offset: Offset.zero,
      hasGesture: true,
      source: MapEventSource.onMultiFinger,
      id: null,
    );

    _lastRotation = details.rotation;
    _lastScale = details.scale;
    _lastLocalFocal = details.localFocalPoint;
  }

  /// gesture has ended, clean up
  void end(ScaleEndDetails details) {
    _lastScale = null;
    _lastLocalFocal = null;
    controller.emitMapEvent(
      MapEventMoveEnd(
        camera: _camera,
        source: MapEventSource.multiFingerEnd,
      ),
    );
  }

  /// Return a rotated Offset
  Offset _rotateOffset(Offset offset) {
    final radians = _camera.rotationRad;
    if (radians == 0) return offset;

    final cos = math.cos(radians);
    final sin = math.sin(radians);
    final nx = (cos * offset.dx) + (sin * offset.dy);
    final ny = (cos * offset.dy) - (sin * offset.dx);

    return Offset(nx, ny);
  }
}

class DragGesture extends Gesture {
  DragGesture({required super.controller});

  void start() {
    controller.emitMapEvent(
      MapEventMoveStart(
        camera: _camera,
        source: MapEventSource.dragStart,
      ),
    );
  }

  void update() {
    // TODO make use of the drag gesture
  }

  void end() {
    controller.emitMapEvent(
      MapEventMoveEnd(
        camera: _camera,
        source: MapEventSource.dragEnd,
      ),
    );
  }
}

class CtrlDragRotateGesture extends Gesture {
  bool isActive = false;

  CtrlDragRotateGesture({required super.controller});

  void start() {
    controller.emitMapEvent(
      MapEventRotateStart(
        camera: _camera,
        source: MapEventSource.ctrlDragRotateStart,
      ),
    );
  }

  void update(ScaleUpdateDetails details) {
    controller.rotate(
      _camera.rotation - (details.focalPointDelta.dy * 0.5),
      hasGesture: true,
      source: MapEventSource.ctrlDragRotate,
      id: null,
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

  bool get ctrlPressed {
    const keys = [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
    ];
    return RawKeyboard.instance.keysPressed
        .where((key) => keys.contains(key))
        .isNotEmpty;
  }
}

class DoubleTapDragZoomGesture extends Gesture {
  bool isActive = false;
  Offset? _focalLocalStart;
  double? _mapZoomStart;

  DoubleTapDragZoomGesture({required super.controller});

  void start(ScaleStartDetails details) {
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
    // TODO make use of the double tap drag zoom gesture
    if (_focalLocalStart == null || _mapZoomStart == null) return;

    final verticalOffset = (_focalLocalStart! - details.localFocalPoint).dy;
    final newZoom = _mapZoomStart! - verticalOffset / 360 * _camera.zoom;
    final min = _options.minZoom ?? 0.0;
    final max = _options.maxZoom ?? double.infinity;
    final actualZoom = math.max(min, math.min(max, newZoom));
    controller.move(
      _camera.center,
      actualZoom,
      offset: Offset.zero,
      hasGesture: true,
      source: MapEventSource.doubleTapHold,
      id: null,
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
