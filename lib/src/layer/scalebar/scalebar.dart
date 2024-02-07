import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart';

part 'painters/simple.dart';
part 'painters/base.dart';
part 'utils.dart';

/// Layer for [FlutterMap] which calculates the scale between screen distance
/// and real distance, and displays it as a scale bar
class Scalebar extends StatelessWidget {
  /// The painter for the scalebar
  ///
  /// It is the [Scalebar]'s responsibility to calculate the scale and visual
  /// sizing of the scale bar. It is the painter's responsibility to create the
  /// visual information.
  ///
  /// Defaults to [SimpleScalebarPainter].
  final ScalebarPainter painter;

  final int _relWidth;

  /// Create a new [Scalebar]
  ///
  /// This widget must be placed in the [FlutterMap.children] list.
  Scalebar({
    super.key,
    ScalebarPainter? painter,
    int relativeWidth = 3,
  })  : painter = painter ??= SimpleScalebarPainter(),
        assert(
          relativeWidth >= 1 && relativeWidth <= 6,
          'The Scalebar `relativeWidth` parameter value is not allowed. '
          'The min is 0 and the max value 6.',
        ),
        _relWidth = relativeWidth - 4;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final index =
        max(0, min(_scale.length - 1, camera.zoom.round() - _relWidth));
    final distance = _scale[index];
    final center = camera.center;
    final start = camera.project(center);
    final targetPoint = calculateEndingGlobalCoordinates(
      start: center,
      startBearing: 90,
      distance: distance.toDouble(),
    );
    final end = camera.project(targetPoint);

    return CustomPaint(
      painter: painter
        ..scaleWidth = end.x - start.x
        ..scaleDistance = distance,
    );
  }
}

const _scale = <int>[
  15000000,
  8000000,
  4000000,
  2000000,
  1000000,
  500000,
  250000,
  100000,
  50000,
  25000,
  15000,
  8000,
  4000,
  2000,
  1000,
  500,
  250,
  100,
  50,
  25,
  10,
  5,
  2,
  1,
];
