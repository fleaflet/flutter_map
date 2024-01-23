import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math.dart';

part 'double_tap.dart';
part 'double_tap_drag_zoom.dart';
part 'drag.dart';
part 'key_trigger_click_rotate.dart';
part 'key_trigger_drag_rotate.dart';
part 'long_press.dart';
part 'scroll_wheel_zoom.dart';
part 'tap.dart';
part 'trackpad_legacy_zoom.dart';
part 'trackpad_zoom.dart';
part 'two_finger.dart';

/// Abstract base service class for every gesture service.
abstract class _BaseGestureService {
  final MapControllerImpl controller;

  const _BaseGestureService({required this.controller});

  /// Getter to provide a short way to access the [MapCamera].
  MapCamera get _camera => controller.camera;

  /// Getter to provide a short way to access the [MapOptions].
  MapOptions get _options => controller.options;
}

/// Abstract base service for a gesture that fires only one time.
/// Commonly used by the different kind of tap gestures.
abstract class _SingleShotGestureService extends _BaseGestureService {
  _SingleShotGestureService({required super.controller});

  TapDownDetails? details;

  void setDetails(TapDownDetails newDetails) => details = newDetails;

  /// Called when the gesture fires and is confirmed.
  void submit();

  void reset() => details = null;
}

/// Abstract base service for a long-press gesture that receives a
/// [LongPressStartDetails] when called.
abstract interface class _BaseLongPressGestureService {
  /// Called when the gesture fires and is confirmed.
  void submit(LongPressStartDetails details);
}

/// Abstract base service for a gesture that fires multiple times time.
abstract interface class _ProgressableGestureService {
  /// Called when the gesture is started, stores important values.
  void start(ScaleStartDetails details);

  /// Called when the gesture receives an update, updates the [MapCamera].
  void update(ScaleUpdateDetails details);

  /// Called when the gesture ends, cleans up the previously stored values.
  void end(ScaleEndDetails details);
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
