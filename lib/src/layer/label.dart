import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:polylabel/polylabel.dart';

class Label {
  static void paintText(
    Canvas canvas,
    List<Offset> points,
    String? labelText,
    TextStyle? labelStyle, {
    PolygonLabelPlacement labelPlacement = PolygonLabelPlacement.polylabel,
  }) {
    late Offset placementPoint;
    switch (labelPlacement) {
      case PolygonLabelPlacement.centroid:
        placementPoint = _computeCentroid(points);
        break;
      case PolygonLabelPlacement.polylabel:
        placementPoint = _computePolylabel(points);
        break;
    }

    var dx = placementPoint.dx;
    var dy = placementPoint.dy;

    final textSpan = TextSpan(text: labelText, style: labelStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    if (dx > 0) {
      textPainter.layout(minWidth: 0, maxWidth: double.infinity);
      dx -= textPainter.width / 2;
      dy -= textPainter.height / 2;

      var maxDx = 0.0;
      var minDx = double.infinity;
      for (final point in points) {
        maxDx = math.max(maxDx, point.dx);
        minDx = math.min(minDx, point.dx);
      }

      if (maxDx - minDx > textPainter.width) {
        textPainter.paint(
          canvas,
          Offset(dx, dy),
        );
      }
    }
  }

  static Offset _computeCentroid(List<Offset> points) {
    return Offset(
      points.map((e) => e.dx).toList().average,
      points.map((e) => e.dy).toList().average,
    );
  }

  static Offset _computePolylabel(List<Offset> points) {
    final labelPosition = polylabel([
      points.map((p) => math.Point(p.dx, p.dy)).toList(),
    ]);
    return Offset(
      labelPosition.point.x.toDouble(),
      labelPosition.point.y.toDouble(),
    );
  }
}
