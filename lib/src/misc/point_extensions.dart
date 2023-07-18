import 'dart:math';
import 'dart:ui';

@Deprecated(
  'Prefer `Point`. '
  'This class has been deprecated in favor of adding extension methods to Point. '
  'This class is deprecated since v6.',
)
typedef CustomPoint<T extends num> = Point<T>;

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

  Point<int> toIntPoint() => Point<int>(x.toInt(), y.toInt());

  Point<double> toDoublePoint() => Point<double>(x.toDouble(), y.toDouble());

  Offset toOffset() => Offset(x.toDouble(), y.toDouble());
}

/// This extension contains methods which, if defined on Point<T extends num>,
/// could cause a runtime error when called on a Point<int> with a non-int
/// argument. An example:
///
/// Point<int>(1, 2).subtract(1.5) would cause a runtime error because the
/// resulting x/y values are doubles and the return value is a Point<int> since
/// the method returns Point<T>.
///
/// Note that division methods (unscaleBy and the / operator) are defined on
/// Point<T extends num> with a Point<double> return argument because division
/// always returns a double.
extension DoublePointExtension on Point<double> {
  /// Subtract [other] from this Point.
  Point<double> subtract(Point<num> other) {
    return Point(x - other.x, y - other.y);
  }

  /// Add [other] to this Point.
  Point<double> add(Point<num> other) {
    return Point(x + other.x, y + other.y);
  }

  /// Create a new [Point] where [x] and [y] values are scaled by the respective
  /// values in [other].
  Point<double> scaleBy(Point<num> other) {
    return Point<double>(x * other.x, y * other.y);
  }
}

/// This extension contains methods which, if defined on Point<T extends num>,
/// could cause a runtime error when called on a Point<int> with a non-int
/// argument. An example:
///
/// Point<int>(1, 2).subtract(1.5) would cause a runtime error because the
/// resulting x/y values are doubles and the return value is a Point<int> since
/// the method returns Point<T>.
///
/// The methods in this extension only take Point<int> arguments to prevent
/// this.
extension IntegerPointExtension on Point<int> {
  /// Subtract [other] from this Point.
  Point<int> subtract(Point<int> other) {
    return Point(x - other.x, y - other.y);
  }

  /// Add [other] to this Point.
  Point<int> add(Point<int> other) {
    return Point(x + other.x, y + other.y);
  }

  /// Create a new [Point] where [x] and [y] values are scaled by the respective
  /// values in [other].
  Point<int> scaleBy(Point<int> other) {
    return Point<int>(x * other.x, y * other.y);
  }
}

extension OffsetToPointExtension on Offset {
  @Deprecated(
    'Prefer `toPoint()`. '
    "This method has been renamed as a result of CustomPoint's removal. "
    'This method is deprecated since v6.',
  )
  Point<double> toCustomPoint() => toPoint();

  /// Creates a [Point] representation of this offset.
  Point<double> toPoint() => Point(dx, dy);
}
