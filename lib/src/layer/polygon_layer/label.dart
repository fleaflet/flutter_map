import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/src/layer/polygon_layer/polygon_layer.dart';
import 'package:latlong2/latlong.dart';
import 'package:polylabel/polylabel.dart';

void Function(Canvas canvas)? buildLabelTextPainter({
  required Offset placementPoint,
  required List<Offset> points,
  required String labelText,
  required double rotationRad,
  required bool rotate,
  required TextStyle labelStyle,
  required double padding,
}) {
  final textSpan = TextSpan(text: labelText, style: labelStyle);
  final textPainter = TextPainter(
    text: textSpan,
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();

  final dx = placementPoint.dx - textPainter.width / 2;
  final dy = placementPoint.dy - textPainter.height / 2;

  double maxDx = 0;
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

      textPainter.paint(canvas, Offset(dx, dy));
      if (rotate) {
        canvas.restore();
      }
    };
  }
  return null;
}

LatLng computeLabelPosition(
    PolygonLabelPlacement labelPlacement, List<LatLng> points) {
  return switch (labelPlacement) {
    PolygonLabelPlacement.centroid => _computeCentroid(points),
    PolygonLabelPlacement.polylabel => _computePolylabel(points),
  };
}

LatLng _computeCentroid(List<LatLng> points) {
  return LatLng(
    points.map((e) => e.latitude).average,
    points.map((e) => e.longitude).average,
  );
}

LatLng _computePolylabel(List<LatLng> points) {
  final labelPosition = polylabel(
    [
      List<math.Point>.generate(points.length,
          (i) => math.Point(points[i].longitude, points[i].latitude)),
    ],
    // "precision" is a bit of a misnomer. It's a threshold for when to stop
    // dividing-and-conquering the polygon in the hopes of finding a better
    // point with more distance to the polygon's outline. It's given in
    // point-units, i.e. degrees here. A bigger number means less precision,
    // i.e. cheaper at the expense off less optimal label placement.
    precision: 0.000001,
  );
  return LatLng(
    labelPosition.point.y.toDouble(),
    labelPosition.point.x.toDouble(),
  );
}
