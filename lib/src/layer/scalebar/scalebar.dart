import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

part 'painter/base.dart';
part 'painter/simple.dart';

/// The [Scalebar] widget is a map layer for [FlutterMap].
class Scalebar extends StatelessWidget {
  /// The [Alignment] of the Scalebar.
  ///
  /// Defaults to [Alignment.topLeft]
  final Alignment alignment;

  /// The [TextStyle] for the scale bar label.
  ///
  /// Defaults to a black color and font size 14.
  final TextStyle? textStyle;

  /// The color of the lines.
  ///
  /// Defaults to black.
  final Color lineColor;

  /// The width of the line strokes in pixel.
  ///
  /// Defaults to 2px.
  final double strokeWidth;

  /// The height of the line strokes in pixel.
  ///
  /// Defaults to 5px.
  final double lineHeight;

  /// The padding of the scale bar.
  ///
  /// Defaults to 10px on all sides.
  final EdgeInsets padding;

  /// Internal relative width, calculated of the relativeLength parameter.
  final int _relLength;

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

    /// The relative length of the scalebar where 0 is minimal and 6 is maximal.
    ///
    /// Defaults to 3.
    int relativeLength = 3,
  })  : assert(
          relativeLength >= 1 && relativeLength <= 6,
          'The Scalebar `relativeWidth` parameter value is not allowed. '
          'The min is 0 and the max value 6.',
        ),
        _relLength = relativeLength - 4;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final metricDst = _metricScale[
        (camera.zoom.round() - _relLength).clamp(0, _metricScale.length - 1)];

    // calculate the scalebar width in pixels
    final latLngCenter = camera.center;
    final offsetCenter = camera.project(latLngCenter);

    final latLngDistance = const Distance().offset(
      latLngCenter,
      metricDst.toDouble(),
      90,
    );
    final offsetDistance = camera.project(latLngDistance);

    final label = metricDst < 1000
        ? '$metricDst m'
        : '${(metricDst / 1000.0).toStringAsFixed(0)} km';
    final ScalebarPainter scalebarPainter = _SimpleScalebarPainter(
      scalebarLength: offsetDistance.x - offsetCenter.x,
      text: TextSpan(style: textStyle, text: label),
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

const _metricScale = <int>[
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
