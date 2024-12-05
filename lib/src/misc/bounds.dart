import 'dart:math' as math hide Point;
import 'dart:math' show Point;
import 'dart:ui';

import 'package:flutter_map/src/misc/extensions.dart';
import 'package:meta/meta.dart';

/// Rectangular bound delimited by orthogonal lines passing through two
/// points.
@immutable
class Bounds<T extends num> {
  /// The edge of the bounds with the minimum x and y coordinate
  final Point<T> min;

  /// The edge of the bounds with the maximum x and y coordinate
  final Point<T> max;

  /// Create a [Bounds] instance in a safe way.
  factory Bounds(Point<T> a, Point<T> b) {
    final T minX;
    final T maxX;
    if (a.x > b.x) {
      minX = b.x;
      maxX = a.x;
    } else {
      minX = a.x;
      maxX = b.x;
    }
    final T minY;
    final T maxY;
    if (a.y > b.y) {
      minY = b.y;
      maxY = a.y;
    } else {
      minY = a.y;
      maxY = b.y;
    }
    return Bounds.unsafe(Point<T>(minX, minY), Point<T>(maxX, maxY));
  }

  /// Create a [Bounds] instance **without** checking if [min] is actually the
  /// minimum and [max] is actually the maximum.
  const Bounds.unsafe(this.min, this.max);

  /// Creates a new [Bounds] obtained by expanding the current ones with a new
  /// point.
  Bounds<T> extend(Point<T> point) {
    return Bounds.unsafe(
      Point(math.min(point.x, min.x), math.min(point.y, min.y)),
      Point(math.max(point.x, max.x), math.max(point.y, max.y)),
    );
  }

  /// This [Bounds] central point.
  Offset get center => (min.toOffset() + max.toOffset()) / 2;

  /// Bottom-Left corner's point.
  Point<T> get bottomLeft => Point(min.x, max.y);

  /// Top-Right corner's point.
  Point<T> get topRight => Point(max.x, min.y);

  /// Top-Left corner's point.
  Point<T> get topLeft => min;

  /// Bottom-Right corner's point.
  Point<T> get bottomRight => max;

  /// A point that contains the difference between the point's axis projections.
  Point<T> get size {
    return max - min;
  }

  /// Check if a [Point] is inside of the bounds.
  bool contains(Point<T> point) {
    return (point.x >= min.x) &&
        (point.x <= max.x) &&
        (point.y >= min.y) &&
        (point.y <= max.y);
  }

  /// Calculates the intersection of two Bounds. The return value will be null
  /// if there is no intersection. The returned bounds may be zero size
  /// (bottomLeft == topRight).
  Bounds<T>? intersect(Bounds<T> b) {
    final leftX = math.max(min.x, b.min.x);
    final rightX = math.min(max.x, b.max.x);
    final topY = math.max(min.y, b.min.y);
    final bottomY = math.min(max.y, b.max.y);

    if (leftX <= rightX && topY <= bottomY) {
      return Bounds.unsafe(Point(leftX, topY), Point(rightX, bottomY));
    }

    return null;
  }

  @override
  String toString() => 'Bounds($min, $max)';
}
