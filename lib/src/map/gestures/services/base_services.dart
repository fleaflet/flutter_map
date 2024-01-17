import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

part 'double_tap.dart';
part 'double_tap_drag_zoom.dart';
part 'drag.dart';
part 'key_trigger_drag_rotate.dart';
part 'long_press.dart';
part 'scroll_wheel_zoom.dart';
part 'tap.dart';
part 'two_finger.dart';

/// Abstract base service class for every gesture service.
abstract class BaseGestureService {
  final MapControllerImpl controller;

  const BaseGestureService({required this.controller});

  /// Getter to provide a short way to access the [MapCamera].
  MapCamera get _camera => controller.camera;

  /// Getter to provide a short way to access the [MapOptions].
  MapOptions get _options => controller.options;
}

/// Abstract base service that additionally stores [TapDownDetails] as it is
/// commonly used by the different kind of tap gestures.
abstract class SingleShotGestureService extends BaseGestureService {
  SingleShotGestureService({required super.controller});

  @mustCallSuper
  @mustBeOverridden
  void submit() {
    controller.stopAnimationRaw();
  }
}

/// mixin that adds the [setDetails] method to a GestureService. Is used if the
/// [TapDownDetails] are set at a different time of when the gesture gets
/// confirmed and submitted.
mixin SetTapDownDetailsMixin on BaseGestureService {
  TapDownDetails? details;

  void setDetails(TapDownDetails newDetails) => details = newDetails;

  void reset() => details = null;
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
