import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/src/layer/polygon_layer/polygon_layer.dart';
import 'package:flutter_map/src/misc/point_extensions.dart';
import 'package:polylabel/polylabel.dart';

void Function(Canvas canvas)? buildLabelTextPainter({
  required String labelText,
  required List<Offset> points,
  required double rotationRad,
  bool rotate = false,
  TextStyle? labelStyle,
  PolygonLabelPlacement labelPlacement = PolygonLabelPlacement.polylabel,
  double padding = 0,
}) {
  final placementPoint = switch (labelPlacement) {
    PolygonLabelPlacement.centroid => _computeCentroid(points),
    PolygonLabelPlacement.polylabel => _computePolylabel(points),
  };

  var dx = placementPoint.dx;
  var dy = placementPoint.dy;

  if (dx > 0) {
    final textSpan = TextSpan(text: labelText, style: labelStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    textPainter.layout();
    dx -= textPainter.width / 2;
    dy -= textPainter.height / 2;

    var maxDx = 0.0;
    var minDx = double.infinity;
    for (final point in points) {
      maxDx = math.max(maxDx, point.dx);
      minDx = math.min(minDx, point.dx);
    }

    if (maxDx - minDx - padding > textPainter.width) {
      return (canvas) {
        if (rotate) {
          canvas.save();
          canvas.translate(placementPoint.dx, placementPoint.dy);
          canvas.rotate(-rotationRad);
          canvas.translate(-placementPoint.dx, -placementPoint.dy);
        }
        textPainter.paint(
          canvas,
          Offset(dx, dy),
        );
        if (rotate) {
          canvas.restore();
        }
      };
    }
  }
  return null;
}

Offset _computeCentroid(List<Offset> points) {
  return Offset(
    points.map((e) => e.dx).average,
    points.map((e) => e.dy).average,
  );
}

Offset _computePolylabel(List<Offset> points) {
  final labelPosition = polylabel([
    List<math.Point>.generate(
        points.length, (i) => math.Point(points[i].dx, points[i].dy)),
  ]);
  return labelPosition.point.toOffset();
}
