import 'dart:math';
import 'dart:ui';

/// Extension methods for the math.[Point] class
extension PointExtension<T extends num> on Point<T> {
  /// Create a new [Point] where the [x] and [y] values are divided by [factor].
  @Deprecated('Replace with Offset')
  Point<double> operator /(num factor) {
    return Point<double>(x / factor, y / factor);
  }

  /// Create a new [Point] where the [x] and [y] values are rounded up to the
  /// nearest integer.
  @Deprecated('Replace with Offset')
  Point<int> ceil() {
    return Point<int>(x.ceil(), y.ceil());
  }

  /// Create a new [Point] where the [x] and [y] values are rounded down to the
  /// nearest integer.
  @Deprecated('Replace with Offset')
  Point<int> floor() {
    return Point<int>(x.floor(), y.floor());
  }

  /// Converts to offset
  Offset toOffset() => Offset(x.toDouble(), y.toDouble());
}

/// Extension methods for [Offset]
extension OffsetToPointExtension on Offset {
  /// Creates a [Point] representation of this offset. This is ONLY used for backwards compatibility
  @Deprecated('Only used for backwards compatibility')
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

  /// returns new [Offset] where floorToDouble() is called on [dx] and [dy] independently
  Offset floor() => Offset(dx.floorToDouble(), dy.floorToDouble());

  /// returns new [Offset] where roundToDouble() is called on [dx] and [dy] independently
  Offset round() => Offset(dx.roundToDouble(), dy.roundToDouble());
}
