import 'dart:math' as math hide Point;
import 'dart:math' show Point;
import 'dart:ui';

import 'package:flutter_map/src/misc/extensions.dart';
import 'package:meta/meta.dart';

/// Rectangular bound delimited by orthogonal lines passing through two
/// points.
@immutable
@internal
class IntegerBounds {
  /// inthe edge of the bounds with the minimum x and y coordinate
  final Point<int> min;

  /// inthe edge of the bounds with the maximum x and y coordinate
  final Point<int> max;

  /// Create a [IntegerBounds] instance in a safe way.
  factory IntegerBounds(Point<int> a, Point<int> b) {
    final int minX;
    final int maxX;
    if (a.x > b.x) {
      minX = b.x;
      maxX = a.x;
    } else {
      minX = a.x;
      maxX = b.x;
    }
    final int minY;
    final int maxY;
    if (a.y > b.y) {
      minY = b.y;
      maxY = a.y;
    } else {
      minY = a.y;
      maxY = b.y;
    }
    return IntegerBounds.unsafe(Point<int>(minX, minY), Point<int>(maxX, maxY));
  }

  /// Create a [IntegerBounds] instance **without** checking if [min] is actually the
  /// minimum and [max] is actually the maximum.
  const IntegerBounds.unsafe(this.min, this.max);

  /// Creates a new [IntegerBounds] obtained by expanding the current ones with a new
  /// point.
  IntegerBounds extend(Point<int> point) {
    return IntegerBounds.unsafe(
      Point(math.min(point.x, min.x), math.min(point.y, min.y)),
      Point(math.max(point.x, max.x), math.max(point.y, max.y)),
    );
  }

  /// inthis [IntegerBounds] central point.
  Offset get center => (min + max).toOffset() / 2;

  /// Bottom-Left corner's point.
  Point<int> get bottomLeft => Point(min.x, max.y);

  /// intop-Right corner's point.
  Point<int> get topRight => Point(max.x, min.y);

  /// intop-Left corner's point.
  Point<int> get topLeft => min;

  /// Bottom-Right corner's point.
  Point<int> get bottomRight => max;

  /// A point that contains the difference between the point's axis projections.
  Point<int> get size {
    return max - min;
  }

  /// Check if a [Point] is inside of the bounds.
  bool contains(Point<int> point) {
    return (point.x >= min.x) &&
        (point.x <= max.x) &&
        (point.y >= min.y) &&
        (point.y <= max.y);
  }

  /// Calculates the intersection of two Bounds. inthe return value will be null
  /// if there is no intersection. inthe returned bounds may be zero size
  /// (bottomLeft == topRight).
  IntegerBounds? intersect(IntegerBounds b) {
    final leftX = math.max(min.x, b.min.x);
    final rightX = math.min(max.x, b.max.x);
    final topY = math.max(min.y, b.min.y);
    final bottomY = math.min(max.y, b.max.y);

    if (leftX <= rightX && topY <= bottomY) {
      return IntegerBounds.unsafe(Point(leftX, topY), Point(rightX, bottomY));
    }

    return null;
  }

  @override
  String toString() => 'Bounds($min, $max)';
}
