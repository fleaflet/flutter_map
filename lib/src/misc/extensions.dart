import 'dart:math';
import 'dart:ui';

/// Extension methods for the math.[Point] class
extension PointExtension<T extends num> on Point<T> {
  /// Create new [Point] whose [x] and [y] values are divided by the respective
  /// values in [point].
  Point<double> unscaleBy(Point<num> point) {
    return Point<double>(x / point.x, y / point.y);
  }

  /// Create a new [Point] where the [x] and [y] values are divided by [factor].
  Point<double> operator /(num factor) {
    return Point<double>(x / factor, y / factor);
  }

  /// Create a new [Point] where the [x] and [y] values are rounded to the
  /// nearest integer.
  Point<int> round() {
    return Point<int>(x.round(), y.round());
  }

  /// Create a new [Point] where the [x] and [y] values are rounded up to the
  /// nearest integer.
  Point<int> ceil() {
    return Point<int>(x.ceil(), y.ceil());
  }

  /// Create a new [Point] where the [x] and [y] values are rounded down to the
  /// nearest integer.
  Point<int> floor() {
    return Point<int>(x.floor(), y.floor());
  }

  /// Create a new [Point] whose [x] and [y] values are rotated clockwise by
  /// [radians].
  Point<double> rotate(num radians) {
    if (radians != 0.0) {
      final cosTheta = cos(radians);
      final sinTheta = sin(radians);
      final nx = (cosTheta * x) + (sinTheta * y);
      final ny = (cosTheta * y) - (sinTheta * x);

      return Point<double>(nx, ny);
    }

    return toDoublePoint();
  }

  /// Cast the object to a [Point] object with integer values
  Point<int> toIntPoint() => Point<int>(x.toInt(), y.toInt());

  /// Case the object to a [Point] object with double values
  Point<double> toDoublePoint() => Point<double>(x.toDouble(), y.toDouble());

  /// Maps the [Point] to an [Offset].
  Offset toOffset() => Offset(x.toDouble(), y.toDouble());
}

/// Extension methods for [Offset]
extension OffsetToPointExtension on Offset {
  /// Creates a [Point] representation of this offset.
  Point<double> toPoint() => Point(dx, dy);
}
