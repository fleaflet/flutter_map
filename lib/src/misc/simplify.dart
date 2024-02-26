// implementation based on
// https://github.com/mourner/simplify-js/blob/master/simplify.js

import 'dart:math' as math;

import 'package:flutter_map/src/geo/crs.dart';
import 'package:meta/meta.dart';

/// Internal double-precision point/vector implementation not to be used in publicly.
///
/// This is an optimization. Vector operations on math.Point tend to incur a 20+x
/// penalty due to virtual function overhead caused by reified generics.
///
/// Further note that unlike math.Point, members are mutable to allow object reuse/pooling
/// and therefore reduce GC pressure.
@internal
final class DoublePoint {
  double x;
  double y;

  DoublePoint(this.x, this.y);

  DoublePoint operator -(DoublePoint rhs) => DoublePoint(x - rhs.x, y - rhs.y);

  double distanceSq(DoublePoint rhs) {
    final double dx = x - rhs.x;
    final double dy = y - rhs.y;
    return dx * dx + dy * dy;
  }

  @override
  String toString() => 'DoublePoint($x, $y)';
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
List<DoublePoint> simplifyRadialDist(
  List<DoublePoint> points,
  double sqTolerance,
) {
  DoublePoint prevPoint = points[0];
  final List<DoublePoint> newPoints = [prevPoint];
  late DoublePoint point;
  for (int i = 1, len = points.length; i < len; i++) {
    point = points[i];
    if (point.distanceSq(prevPoint) > sqTolerance) {
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
  List<DoublePoint> points,
  final int first,
  final int last,
  double sqTolerance,
  List<DoublePoint> simplified,
) {
  double maxSqDist = sqTolerance;
  final p0 = points[first];
  final p1 = points[last];

  late int index;
  for (int i = first + 1; i < last; i++) {
    final p = points[i];
    final double sqDist = getSqSegDist(p.x, p.y, p0.x, p0.y, p1.x, p1.y);

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
List<DoublePoint> simplifyDouglasPeucker(
  List<DoublePoint> points,
  double sqTolerance,
) {
  final int last = points.length - 1;
  final List<DoublePoint> simplified = [points[0]];
  _simplifyDPStep(points, 0, last, sqTolerance, simplified);
  simplified.add(points[last]);
  return simplified;
}

/// Simplify the list of points for better performance.
List<DoublePoint> simplifyPoints({
  required final List<DoublePoint> points,
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
