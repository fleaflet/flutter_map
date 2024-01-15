import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

part 'double_tap.dart';
part 'double_tap_drag_zoom.dart';
part 'drag.dart';
part 'key_trigger_drag_rotate.dart';
part 'long_press.dart';
part 'scroll_wheel_zoom.dart';
part 'tap.dart';
part 'two_finger.dart';

abstract class BaseGestureService {
  final MapControllerImpl controller;

  const BaseGestureService({required this.controller});

  MapCamera get _camera => controller.camera;

  MapOptions get _options => controller.options;
}

abstract class BaseDetailsGestureService extends BaseGestureService {
  TapDownDetails? details;

  BaseDetailsGestureService({required super.controller});

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
