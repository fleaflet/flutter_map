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

  Bounds<T> extend(Point<T> point) {
    Point<T> newMin;
    Point<T> newMax;
    if (this.min == null && this.max == null) {
      newMin = point;
      newMax = point;
    } else {
      var minX = math.min(point.x, this.min.x);
      var maxX = math.max(point.x, this.max.x);
      var minY = math.min(point.y, this.min.y);
      var maxY = math.max(point.y, this.max.y);
      newMin = new Point(minX, minY);
      newMax = new Point(maxX, maxY);
    }
    return new Bounds._(newMin, newMax);
  }

  Point<double> getCenter() {
    return new Point<double>(
      (min.x + max.x) / 2,
      (min.y + max.y) / 2,
    );
  }

  Point<T> get bottomLeft => new Point(min.x, max.y);
  Point<T> get topRight => new Point(max.x, min.y);
  Point<T> get topLeft => min;
  Point<T> get bottomRight => max;

  Point<T> get size {
    return this.max - this.min;
  }

  bool contains(Point<T> point) {
    var min = point;
    var max = point;
    return containsBounds(new Bounds(min, max));
  }

  bool containsBounds(Bounds<T> b) {
    return (b.min.x >= this.min.x) &&
        (b.max.x <= this.max.x) &&
        (b.min.y <= this.min.y) &&
        (b.max.y <= this.max.y);
  }

  String toString() => "Bounds($min, $max)";
}
