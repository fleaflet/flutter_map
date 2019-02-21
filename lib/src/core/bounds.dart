import 'dart:math' as math;
import 'point.dart';

class Bounds<T extends num> {
  final CustomPoint<T> min;
  final CustomPoint<T> max;

  factory Bounds(CustomPoint<T> a, CustomPoint<T> b) {
    var bounds1 = new Bounds._(a, b);
    var bounds2 = bounds1.extend(a);
    return bounds2.extend(b);
  }

  const Bounds._(this.min, this.max);

  Bounds<T> extend(CustomPoint<T> point) {
    CustomPoint<T> newMin;
    CustomPoint<T> newMax;
    if (this.min == null && this.max == null) {
      newMin = point;
      newMax = point;
    } else {
      var minX = math.min(point.x, this.min.x);
      var maxX = math.max(point.x, this.max.x);
      var minY = math.min(point.y, this.min.y);
      var maxY = math.max(point.y, this.max.y);
      newMin = new CustomPoint(minX, minY);
      newMax = new CustomPoint(maxX, maxY);
    }
    return new Bounds._(newMin, newMax);
  }

  CustomPoint<double> getCenter() {
    return new CustomPoint<double>(
      (min.x + max.x) / 2,
      (min.y + max.y) / 2,
    );
  }

  CustomPoint<T> get bottomLeft => new CustomPoint(min.x, max.y);
  CustomPoint<T> get topRight => new CustomPoint(max.x, min.y);
  CustomPoint<T> get topLeft => min;
  CustomPoint<T> get bottomRight => max;

  CustomPoint<T> get size {
    return this.max - this.min;
  }

  bool contains(CustomPoint<T> point) {
    var min = point;
    var max = point;
    return containsBounds(new Bounds(min, max));
  }

  bool containsBounds(Bounds<T> b) {
    return (b.min.x >= this.min.x) &&
        (b.max.x <= this.max.x) &&
        (b.min.y >= this.min.y) &&
        (b.max.y <= this.max.y);
  }

  String toString() => "Bounds($min, $max)";
}
