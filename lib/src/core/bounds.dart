import 'dart:math' as math;
import 'point.dart';

class Bounds<T extends num> {
  final CustomPoint<T> min;
  final CustomPoint<T> max;

  factory Bounds(CustomPoint<T> a, CustomPoint<T> b) {
    var bounds1 = Bounds._(a, b);
    var bounds2 = bounds1.extend(a);
    return bounds2.extend(b);
  }

  const Bounds._(this.min, this.max);

  Bounds<T> extend(CustomPoint<T> point) {
    CustomPoint<T> newMin;
    CustomPoint<T> newMax;
    if (min == null && max == null) {
      newMin = point;
      newMax = point;
    } else {
      var minX = math.min(point.x, min.x);
      var maxX = math.max(point.x, max.x);
      var minY = math.min(point.y, min.y);
      var maxY = math.max(point.y, max.y);
      newMin = CustomPoint(minX, minY);
      newMax = CustomPoint(maxX, maxY);
    }
    return Bounds._(newMin, newMax);
  }

  CustomPoint<double> getCenter() {
    return CustomPoint<double>(
      (min.x + max.x) / 2,
      (min.y + max.y) / 2,
    );
  }

  CustomPoint<T> get bottomLeft => CustomPoint(min.x, max.y);
  CustomPoint<T> get topRight => CustomPoint(max.x, min.y);
  CustomPoint<T> get topLeft => min;
  CustomPoint<T> get bottomRight => max;

  CustomPoint<T> get size {
    return max - min;
  }

  bool contains(CustomPoint<T> point) {
    var min = point;
    var max = point;
    return containsBounds(Bounds(min, max));
  }

  bool containsBounds(Bounds<T> b) {
    return (b.min.x >= min.x) &&
        (b.max.x <= max.x) &&
        (b.min.y >= min.y) &&
        (b.max.y <= max.y);
  }

  bool containsPartialBounds(Bounds<T> b) {
    return (b.min.x <= max.x) &&
        (b.max.x >= min.x) &&
        (b.min.y <= max.y) &&
        (b.max.y >= min.y);
  }

  @override
  String toString() => 'Bounds($min, $max)';
}
