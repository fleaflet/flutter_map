// implementation based on
// https://github.com/mourner/simplify-js/blob/master/simplify.js

import 'package:latlong2/latlong.dart';

double _getSqDist(
  LatLng p1,
  LatLng p2,
) {
  final double dx = p1.longitude - p2.longitude;
  final double dy = p1.latitude - p2.latitude;
  return dx * dx + dy * dy;
}

// square distance from a point to a segment
double _getSqSegDist(
  LatLng p,
  LatLng p1,
  LatLng p2,
) {
  double x = p1.longitude;
  double y = p1.latitude;
  double dx = p2.longitude - x;
  double dy = p2.latitude - y;
  if (dx != 0 || dy != 0) {
    final double t =
        ((p.longitude - x) * dx + (p.latitude - y) * dy) / (dx * dx + dy * dy);
    if (t > 1) {
      x = p2.longitude;
      y = p2.latitude;
    } else if (t > 0) {
      x += dx * t;
      y += dy * t;
    }
  }

  dx = p.longitude - x;
  dy = p.latitude - y;

  return dx * dx + dy * dy;
}


List<LatLng> simplifyRadialDist(
  List<LatLng> points,
  double sqTolerance,
) {
  LatLng prevPoint = points[0];
  final List<LatLng> newPoints = [prevPoint];
  late LatLng point;
  for (int i = 1, len = points.length; i < len; i++) {
    point = points[i];
    if (_getSqDist(point, prevPoint) > sqTolerance) {
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
  List<LatLng> points,
  int first,
  int last,
  double sqTolerance,
  List<LatLng> simplified,
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
List<LatLng> simplifyDouglasPeucker(
  List<LatLng> points,
  double sqTolerance,
) {
  final int last = points.length - 1;
  final List<LatLng> simplified = [points[0]];
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
  if (points.length <= 2) {
    return points;
  }
  List<LatLng> nextPoints = points;
  final double sqTolerance = tolerance * tolerance;
  nextPoints =
      highestQuality ? points : simplifyRadialDist(nextPoints, sqTolerance);
  nextPoints = simplifyDouglasPeucker(nextPoints, sqTolerance);
  return nextPoints;
}
