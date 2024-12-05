import 'dart:math';
import 'dart:ui';

import 'package:meta/meta.dart';

/// Extension methods for the math.[Point] class
@internal
extension PointExtension<T extends num> on Point<T> {
  /// Create a new [Point] where the [x] and [y] values are divided by [factor].
  Point<double> operator /(num factor) {
    return Point<double>(x / factor, y / factor);
  }

  /// Converts to offset
  Offset toOffset() => Offset(x.toDouble(), y.toDouble());
}

/// Extension methods for [Offset]
@internal
extension OffsetExtension on Offset {

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

  /// returns new [Offset] where floorToDouble() is called on [dx] and [dy] independently
  Offset floor() => Offset(dx.floorToDouble(), dy.floorToDouble());

  /// returns new [Offset] where roundToDouble() is called on [dx] and [dy] independently
  Offset round() => Offset(dx.roundToDouble(), dy.roundToDouble());
}
