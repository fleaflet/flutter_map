// implementation based on
// https://github.com/mourner/simplify-js/blob/master/simplify.js

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_map/src/geo/crs.dart';
import 'package:meta/meta.dart';

double distanceSq(Offset a, Offset b) {
    final double dx = a.dx - b.dx;
    final double dy = a.dy - b.dy;
    return dx * dx + dy * dy;
  }

/// square distance from a point to a segment
double getSqSegDist(
  final double px,
  final double py,
  final double x0,
  final double y0,
  final double x1,
  final double y1,
) {
  double dx = x1 - x0;
  double dy = y1 - y0;
  if (dx != 0 || dy != 0) {
    final double t = ((px - x0) * dx + (py - y0) * dy) / (dx * dx + dy * dy);
    if (t > 1) {
      dx = px - x1;
      dy = py - y1;
      return dx * dx + dy * dy;
    } else if (t > 0) {
      dx = px - (x0 + dx * t);
      dy = py - (y0 + dy * t);
      return dx * dx + dy * dy;
    }
  }

  dx = px - x0;
  dy = py - y0;

  return dx * dx + dy * dy;
}

/// Alternative algorithm to the Douglas Peucker simplification algorithm.
///
/// Might actually be more expensive than DP, which is also better
List<Offset> simplifyRadialDist(
  List<Offset> points,
  double sqTolerance,
) {
  Offset prevPoint = points[0];
  final List<Offset> newPoints = [prevPoint];
  late Offset point;
  for (int i = 1, len = points.length; i < len; i++) {
    point = points[i];
    if (distanceSq(point, prevPoint) > sqTolerance) {
      newPoints.add(point);
      prevPoint = point;
    }
  }
  if (prevPoint != point) {
    newPoints.add(point);
  }
  return newPoints;
}

void _simplifyDPStep(
  List<Offset> points,
  final int first,
  final int last,
  double sqTolerance,
  List<Offset> simplified,
) {
  double maxSqDist = sqTolerance;
  final p0 = points[first];
  final p1 = points[last];

  late int index;
  for (int i = first + 1; i < last; i++) {
    final p = points[i];
    final double sqDist = getSqSegDist(p.dx, p.dy, p0.dx, p0.dy, p1.dx, p1.dy);

    if (sqDist > maxSqDist) {
      index = i;
      maxSqDist = sqDist;
    }
  }
  if (maxSqDist > sqTolerance) {
    if (index - first > 1) {
      _simplifyDPStep(points, first, index, sqTolerance, simplified);
    }
    simplified.add(points[index]);
    if (last - index > 1) {
      _simplifyDPStep(points, index, last, sqTolerance, simplified);
    }
  }
}

/// simplification using the Ramer-Douglas-Peucker algorithm
List<Offset> simplifyDouglasPeucker(
  List<Offset> points,
  double sqTolerance,
) {
  final int last = points.length - 1;
  final List<Offset> simplified = [points[0]];
  _simplifyDPStep(points, 0, last, sqTolerance, simplified);
  simplified.add(points[last]);
  return simplified;
}

/// Simplify the list of points for better performance.
List<Offset> simplifyPoints({
  required final List<Offset> points,
  required double tolerance,
  required bool highQuality,
}) {
  // Don't simplify anything less than a square
  if (points.length <= 4) return points;

  final double sqTolerance = tolerance * tolerance;
  return highQuality
      ? simplifyDouglasPeucker(points, sqTolerance)
      : simplifyRadialDist(points, sqTolerance);
}

/// Calculates the tolerance for the simplification.
double getEffectiveSimplificationTolerance({
  required Crs crs,
  required int zoom,
  required double pixelTolerance,
  required double devicePixelRatio,
}) {
  if (pixelTolerance <= 0) return 0;

  final scale = crs.scale(zoom.toDouble());
  final (x0, y0) = crs.untransform(0, 0, scale);
  final (x1, y1) = crs.untransform(
    pixelTolerance * devicePixelRatio,
    pixelTolerance * devicePixelRatio,
    scale,
  );

  final dx = x1 - x0;
  final dy = y1 - y0;
  return math.sqrt(dx * dx + dy * dy);
}
