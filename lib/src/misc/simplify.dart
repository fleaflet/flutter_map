// implementation based on
// https://github.com/mourner/simplify-js/blob/master/simplify.js

import 'package:latlong2/latlong.dart';

// Custom point due to math.Point<double> being slow. Math operations tend to
// have 20+x penalty for virtual function overhead given the reified nature of
// Dart generics.
class DoublePoint {
  // Note: Allow mutability for reuse/pooling to reduce GC pressure and increase performance.
  // Geometry operations should be safe-by-default to avoid accidental bugs.
  double x;
  double y;

  DoublePoint(this.x, this.y);

  DoublePoint operator -(DoublePoint rhs) => DoublePoint(x - rhs.x, y - rhs.y);

  double distanceSq(DoublePoint rhs) {
    final double dx = x - rhs.x;
    final double dy = y - rhs.y;
    return dx * dx + dy * dy;
  }
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

// simplification using Ramer-Douglas-Peucker algorithm
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

List<LatLng> simplify(
  List<LatLng> points,
  double tolerance, {
  bool highestQuality = false,
}) {
  // Don't simplify anything less than a square
  if (points.length <= 4) return points;

  List<DoublePoint> nextPoints = List<DoublePoint>.generate(
    points.length,
    (i) => DoublePoint(points[i].longitude, points[i].latitude),
  );
  final double sqTolerance = tolerance * tolerance;
  nextPoints =
      highestQuality ? nextPoints : simplifyRadialDist(nextPoints, sqTolerance);
  nextPoints = simplifyDouglasPeucker(nextPoints, sqTolerance);

  return List<LatLng>.generate(
    nextPoints.length,
    (i) => LatLng(nextPoints[i].y, nextPoints[i].x),
  );
}

List<DoublePoint> simplifyPoints(
  final List<DoublePoint> points,
  double tolerance, {
  bool highestQuality = false,
}) {
  // Don't simplify anything less than a square
  if (points.length <= 4) return points;

  List<DoublePoint> nextPoints = points;
  final double sqTolerance = tolerance * tolerance;
  nextPoints =
      highestQuality ? nextPoints : simplifyRadialDist(nextPoints, sqTolerance);
  nextPoints = simplifyDouglasPeucker(nextPoints, sqTolerance);

  return nextPoints;
}
