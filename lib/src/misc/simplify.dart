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
double _getSqSegDist(
  DoublePoint p,
  DoublePoint p1,
  DoublePoint p2,
) {
  double x = p1.x;
  double y = p1.y;
  double dx = p2.x - x;
  double dy = p2.y - y;
  if (dx != 0 || dy != 0) {
    final double t = ((p.x - x) * dx + (p.y - y) * dy) / (dx * dx + dy * dy);
    if (t > 1) {
      x = p2.x;
      y = p2.y;
    } else if (t > 0) {
      x += dx * t;
      y += dy * t;
    }
  }

  dx = p.x - x;
  dy = p.y - y;

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
  int first,
  int last,
  double sqTolerance,
  List<DoublePoint> simplified,
) {
  double maxSqDist = sqTolerance;
  late int index;
  for (int i = first + 1; i < last; i++) {
    final double sqDist = _getSqSegDist(points[i], points[first], points[last]);

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

/// high quality simplification uses the Ramer-Douglas-Peucker algorithm
/// otherwise it just merges close points
List<LatLng> simplify(
  List<LatLng> points,
  double tolerance, {
  bool highestQuality = false,
}) {
  // Don't simplify anything less than a square
  if (points.length <= 4) return points;

  List<DoublePoint> nextPoints = List<DoublePoint>.generate(points.length,
      (i) => DoublePoint(points[i].longitude, points[i].latitude));
  final double sqTolerance = tolerance * tolerance;
  nextPoints =
      highestQuality ? nextPoints : simplifyRadialDist(nextPoints, sqTolerance);
  nextPoints = simplifyDouglasPeucker(nextPoints, sqTolerance);

  return List<LatLng>.generate(
      nextPoints.length, (i) => LatLng(nextPoints[i].y, nextPoints[i].x));
}

List<DoublePoint> simplifyPoints(
  List<DoublePoint> points,
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
