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

  /// Converts to offset
  Offset toOffset () => Offset(x.toDouble(), y.toDouble());

}

/// Extension methods for [Offset]
extension OffsetToPointExtension on Offset {

  /// Creates a [Point] representation of this offset.
  Point<double> toPoint() => Point(dx, dy);

  /// Create a new [Offset] whose [dx] and [dy] values are rotated clockwise by
  /// [radians].
  Offset rotate(num radians) {
    final cosTheta = cos(radians);
    final sinTheta = sin(radians);
    final nx = (cosTheta * dx) + (sinTheta * dy);
    final ny = (cosTheta * dy) - (sinTheta * dx);
    return Offset(nx, ny);
  }
}
