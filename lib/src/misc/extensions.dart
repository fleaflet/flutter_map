import 'dart:math' as math;
import 'dart:ui';

import 'package:meta/meta.dart';

/// Extension methods for the math.[Point] class
@internal
extension PointExtension<T extends num> on math.Point<T> {
  /// Create a new [Point] where the [x] and [y] values are divided by [factor].
  math.Point<double> operator /(num factor) {
    return math.Point<double>(x / factor, y / factor);
  }

  /// Converts to offset
  Offset toOffset() => Offset(x.toDouble(), y.toDouble());
}

/// Extension methods for [Offset]
@internal
extension OffsetExtension on Offset {
  /// Creates a [Point] representation of this offset.
  math.Point<double> toPoint() => math.Point(dx, dy);

  /// Create a new [Offset] whose [dx] and [dy] values are rotated clockwise by
  /// [radians].
  Offset rotate(num radians) {
    final cosTheta = math.cos(radians);
    final sinTheta = math.sin(radians);
    final nx = (cosTheta * dx) + (sinTheta * dy);
    final ny = (cosTheta * dy) - (sinTheta * dx);
    return Offset(nx, ny);
  }

  /// returns new [Offset] where floorToDouble() is called on [dx] and [dy] independently
  Offset floor() => Offset(dx.floorToDouble(), dy.floorToDouble());

  /// returns new [Offset] where roundToDouble() is called on [dx] and [dy] independently
  Offset round() => Offset(dx.roundToDouble(), dy.roundToDouble());
}

@internal
extension RectExtension on Rect {
  /// Create a [Rect] as bounding box of a list of points.
  static Rect containing(List<Offset> points) {
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    var minX = double.infinity;
    var minY = double.infinity;

    for (final point in points) {
      maxX = math.max(point.dx, maxX);
      minX = math.min(point.dx, minX);
      maxY = math.max(point.dy, maxY);
      minY = math.min(point.dy, minY);
    }

    return Rect.fromPoints(Offset(minX, minY), Offset(maxX, maxY));
  }

  /// Checks if the line between the two coordinates is contained within the
  /// [Rect].
  bool aabbContainsLine(double x1, double y1, double x2, double y2) {
    // Completely outside.
    if ((x1 <= left && x2 <= left) ||
        (y1 <= top && y2 <= top) ||
        (x1 >= right && x2 >= right) ||
        (y1 >= bottom && y2 >= bottom)) {
      return false;
    }

    final m = (y2 - y1) / (x2 - x1);

    double y = m * (left - x1) + y1;
    if (y > top && y < bottom) return true;

    y = m * (right - x1) + y1;
    if (y > top && y < bottom) return true;

    double x = (top - y1) / m + x1;
    if (x > left && x < right) return true;

    x = (bottom - y1) / m + x1;
    if (x > left && x < right) return true;

    return false;
  }

  Offset get min => topLeft;

  Offset get max => bottomRight;
}
