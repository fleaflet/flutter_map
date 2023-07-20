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
    TextStyle? labelStyle,
    double rotationRad, {
    bool rotate = false,
    PolygonLabelPlacement labelPlacement = PolygonLabelPlacement.polylabel,
  }) {
    final placementPoint = switch (labelPlacement) {
      PolygonLabelPlacement.centroid => _computeCentroid(points),
      PolygonLabelPlacement.polylabel => _computePolylabel(points),
    };

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
      textPainter.layout();
      dx -= textPainter.width / 2;
      dy -= textPainter.height / 2;

      var maxDx = 0.0;
      var minDx = double.infinity;
      for (final point in points) {
        maxDx = math.max(maxDx, point.dx);
        minDx = math.min(minDx, point.dx);
      }

      if (maxDx - minDx > textPainter.width) {
        canvas.save();
        if (rotate) {
          canvas.translate(placementPoint.dx, placementPoint.dy);
          canvas.rotate(-rotationRad);
          canvas.translate(-placementPoint.dx, -placementPoint.dy);
        }
        textPainter.paint(
          canvas,
          Offset(dx, dy),
        );
        canvas.restore();
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
    return labelPosition.point.toOffset();
  }
}
