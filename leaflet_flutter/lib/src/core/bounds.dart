import 'dart:math' as math;
import 'point.dart';

class Bounds<T extends num> {
  final Point<T> min;
  final Point<T> max;

  factory Bounds(Point<T> a, Point<T> b) {
    var bounds1 = new Bounds._(a, b);
    var bounds2 = bounds1.extend(a);
    return bounds2.extend(b);
  }

  const Bounds._(this.min, this.max);

  Bounds extend(Point<T> point) {
    Point<T> newMin;
    Point<T> newMax;
    if (this.min == null && this.max == null) {
      newMin = point;
      newMax = point;
    } else {
      var minX = math.min(point.x, point.x);
      var maxX = math.max(point.x, this.max.x);
      var minY = math.min(point.y, this.min.y);
      var maxY = math.max(point.y, this.max.y);
      newMin = new Point(minX, minY);
      newMax = new Point(maxX, maxY);
    }
    return new Bounds._(newMin, newMax);
  }

  Point getCenter() {
    return new Point(
      (min.x + max.x) / 2,
      (min.y + max.y) / 2,
    );
  }

  String toString() => "Bounds($min, $max)";
}
