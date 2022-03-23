import 'dart:math' as math;

/// Data represenation of point located on map instance
/// where [x] is horizontal and [y] is vertical pixel value
class CustomPoint<T extends num> extends math.Point<T> {
  const CustomPoint(num x, num y) : super(x as T, y as T);

  /// Create new [CustomPoint] whose [x] and [y] values are divided by [factor]
  CustomPoint<T> operator /(num /*T|int*/ factor) {
    return CustomPoint<T>(x / factor, y / factor);
  }

  /// Create new [CustomPoint] whose [x] and [y] values are rounded up
  /// to int
  CustomPoint<T> ceil() {
    return CustomPoint(x.ceil(), y.ceil());
  }

  /// Create new [CustomPoint] whose [x] and [y] values are rounded down
  /// to int
  CustomPoint<T> floor() {
    return CustomPoint<T>(x.floor(), y.floor());
  }

  /// Create new [CustomPoint] whose [x] and [y] values are divided by
  /// other [point] values
  CustomPoint<T> unscaleBy(CustomPoint<T> point) {
    return CustomPoint<T>(x / point.x, y / point.y);
  }

  /// Create new [CustomPoint] where [other] point values [x] and [y] are added
  @override
  CustomPoint<T> operator +(math.Point<T> other) {
    return CustomPoint<T>(x + other.x, y + other.y);
  }

  /// Create new [CustomPoint] where [x] and [y] values are subtracted from
  /// [other] point [x] and [y] values
  @override
  CustomPoint<T> operator -(math.Point<T> other) {
    return CustomPoint<T>(x - other.x, y - other.y);
  }

  /// Create new [CustomPoint] where [x] and [y] are multiplied by [factor]
  @override
  CustomPoint<T> operator *(num /*T|int*/ factor) {
    return CustomPoint<T>((x * factor), (y * factor));
  }

  /// Create new [CustomPoint] where [x] and [y] are scaled by [point] values
  CustomPoint scaleBy(CustomPoint point) {
    return CustomPoint(x * point.x, y * point.y);
  }

  /// Create new [CustomPoint] where [x] and [y] is rounded to int
  CustomPoint round() {
    final x = this.x is double ? this.x.round() : this.x;
    final y = this.y is double ? this.y.round() : this.y;
    return CustomPoint(x, y);
  }

  /// Create new [CustomPoint] with [x] and [y] multiplied by [n]
  CustomPoint multiplyBy(num n) {
    return CustomPoint(x * n, y * n);
  }

  /// Create new [CustomPoint] whose [x] and [y] values are rotated by [radians]
  /// in clockwise fashion
  CustomPoint rotate(num radians) {
    if (radians != 0.0) {
      final cos = math.cos(radians);
      final sin = math.sin(radians);
      final nx = (cos * x) + (sin * y);
      final ny = (cos * y) - (sin * x);

      return CustomPoint(nx, ny);
    }

    return this;
  }

  @override
  String toString() => 'CustomPoint ($x, $y)';
}
