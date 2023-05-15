import 'dart:math' as math;

/// Data represenation of point located on map instance
/// where [x] is horizontal and [y] is vertical pixel value
class CustomPoint<T extends num> extends math.Point<T> {
  const CustomPoint(super.x, super.y);

  /// Create new [CustomPoint] where [x] and [y] values are added to [other]
  /// point [x] and [y] values
  @override
  CustomPoint<T> operator +(math.Point other) {
    return CustomPoint<T>((x + other.x) as T, (y + other.y) as T);
  }

  /// Create new [CustomPoint] where [x] and [y] values are subtracted from
  /// [other] point [x] and [y] values
  @override
  CustomPoint<T> operator -(math.Point other) {
    return CustomPoint<T>((x - other.x) as T, (y - other.y) as T);
  }

  /// Create new [CustomPoint] where [x] and [y] values are scaled by [point]
  /// values
  CustomPoint<T> scaleBy(CustomPoint<T> point) {
    return CustomPoint<T>((x * point.x) as T, (y * point.y) as T);
  }

  /// Create new [CustomPoint] whose [x] and [y] values are divided by other
  /// [point] values
  CustomPoint<double> unscaleBy(CustomPoint<T> point) {
    return CustomPoint<double>(x / point.x, y / point.y);
  }

  /// Create new [CustomPoint] where [x] and [y] values are multiplied by
  /// [factor]
  @override
  CustomPoint<T> operator *(num factor) {
    return CustomPoint<T>((x * factor) as T, (y * factor) as T);
  }

  /// Create new [CustomPoint] where [x] and [y] values are divided by [factor]
  CustomPoint<T> operator /(num factor) {
    return CustomPoint<T>((x / factor) as T, (y / factor) as T);
  }

  /// Create new [CustomPoint] where [x] and [y] is rounded to int
  CustomPoint<int> round() {
    return CustomPoint<int>(x.round(), y.round());
  }

  /// Create new [CustomPoint] where [x] and [y] values are rounded up to int
  CustomPoint<int> ceil() {
    return CustomPoint<int>(x.ceil(), y.ceil());
  }

  /// Create new [CustomPoint] where [x] and [y] values are rounded down to int
  CustomPoint<int> floor() {
    return CustomPoint<int>(x.floor(), y.floor());
  }

  /// Create new [CustomPoint] whose [x] and [y] values are rotated by [radians]
  /// in clockwise fashion
  CustomPoint<double> rotate(num radians) {
    if (radians != 0.0) {
      final cos = math.cos(radians);
      final sin = math.sin(radians);
      final nx = (cos * x) + (sin * y);
      final ny = (cos * y) - (sin * x);

      return CustomPoint<double>(nx, ny);
    }

    return CustomPoint(x.toDouble(), y.toDouble());
  }

  CustomPoint<int> toIntPoint() => CustomPoint<int>(x.toInt(), y.toInt());

  CustomPoint<double> toDoublePoint() =>
      CustomPoint<double>(x.toDouble(), y.toDouble());

  @override
  String toString() => 'CustomPoint ($x, $y)';
}
