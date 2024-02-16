import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart';

part 'painter/base.dart';
part 'painter/simple.dart';
part 'utils.dart';

/// The [Scalebar] widget is a map layer for [FlutterMap].
class Scalebar extends StatelessWidget {
  final Alignment alignment;
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
    this.alignment = Alignment.topRight,
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
    final distance =
        _scale[(camera.zoom.round() - _relWidth).clamp(0, _scale.length - 1)];

    // calculate the scalebar width in pixels
    final latLngCenter = camera.center;
    final offsetCenter = camera.project(latLngCenter);

    final latLngDistance = _calculateLatLngInDistance(
      start: latLngCenter,
      bearing: 90,
      distance: distance.toDouble(),
    );
    final offsetDistance = camera.project(latLngDistance);

    final ScalebarPainter scalebarPainter = _SimpleScalebarPainter(
      scalebarLength: offsetDistance.x - offsetCenter.x,
      label: distance < 1000
          ? '$distance m'
          : '${(distance / 1000.0).toStringAsFixed(0)} km',
      lineColor: lineColor,
      strokeWidth: strokeWidth,
      lineHeight: lineHeight,
      textStyle: textStyle,
    );

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: CustomPaint(
          size: scalebarPainter.widgetSize,
          painter: scalebarPainter,
        ),
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
