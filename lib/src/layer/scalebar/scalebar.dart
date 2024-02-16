import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart';

part 'painter.dart';
part 'utils.dart';

/// The [Scalebar] widget is a map layer for [FlutterMap].
class Scalebar extends StatelessWidget {
  final TextStyle? textStyle;
  final Color lineColor;
  final double strokeWidth;
  final double lineHeight;
  final EdgeInsets padding;
  final int _relWidth;

  /// Create a new [Scalebar].
  ///
  /// This widget needs to be placed in the [FlutterMap.children] list.
  const Scalebar({
    super.key,
    this.textStyle = const TextStyle(color: Color(0xFF000000), fontSize: 14),
    this.lineColor = const Color(0xFF000000),
    this.strokeWidth = 2,
    this.lineHeight = 5,
    this.padding = const EdgeInsets.all(10),
    int relativeWidth = 3,
  })  : assert(
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
    final targetPoint = _calculateEndingGlobalCoordinates(
      start: center,
      startBearing: 90,
      distance: distance.toDouble(),
    );
    final end = camera.project(targetPoint);

    return CustomPaint(
      painter: ScalebarPainter(
        width: end.x - start.x,
        text: distance > 999
            ? '${(distance / 1000.0).toStringAsFixed(0)} km'
            : '$distance m',
        lineColor: lineColor,
        strokeWidth: strokeWidth,
        padding: padding,
        lineHeight: lineHeight,
        textStyle: textStyle,
      ),
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
