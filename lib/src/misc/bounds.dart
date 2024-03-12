import 'dart:math' as math hide Point;
import 'dart:math' show Point;

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

  /// Create a [Bounds] as bounding box of a list of points.
  static Bounds<double> containing(Iterable<Point<double>> points) {
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    var minX = double.infinity;
    var minY = double.infinity;

    for (final point in points) {
      maxX = math.max(point.x, maxX);
      minX = math.min(point.x, minX);
      maxY = math.max(point.y, maxY);
      minY = math.min(point.y, minY);
    }

    return Bounds.unsafe(Point(minX, minY), Point(maxX, maxY));
  }

  /// Creates a new [Bounds] obtained by expanding the current ones with a new
  /// point.
  Bounds<T> extend(Point<T> point) {
    return Bounds.unsafe(
      Point(math.min(point.x, min.x), math.min(point.y, min.y)),
      Point(math.max(point.x, max.x), math.max(point.y, max.y)),
    );
  }

  /// This [Bounds] central point.
  Point<double> get center => Point<double>(
        (min.x + max.x) / 2,
        (min.y + max.y) / 2,
      );

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

  /// Check if an other [Bounds] object is inside of the bounds.
  bool containsBounds(Bounds<T> b) {
    return (b.min.x >= min.x) &&
        (b.max.x <= max.x) &&
        (b.min.y >= min.y) &&
        (b.max.y <= max.y);
  }

  /// Checks if a part of the other [Bounds] is contained in this [Bounds].
  bool containsPartialBounds(Bounds<T> b) {
    return (b.min.x <= max.x) &&
        (b.max.x >= min.x) &&
        (b.min.y <= max.y) &&
        (b.max.y >= min.y);
  }

  /// Checks if the line between the two coordinates is contained within the
  /// [Bounds].
  bool aabbContainsLine(double x1, double y1, double x2, double y2) {
    // Completely outside.
    if ((x1 <= min.x && x2 <= min.x) ||
        (y1 <= min.y && y2 <= min.y) ||
        (x1 >= max.x && x2 >= max.x) ||
        (y1 >= max.y && y2 >= max.y)) {
      return false;
    }

    final m = (y2 - y1) / (x2 - x1);

    double y = m * (min.x - x1) + y1;
    if (y > min.y && y < max.y) return true;

    y = m * (max.x - x1) + y1;
    if (y > min.y && y < max.y) return true;

    double x = (min.y - y1) / m + x1;
    if (x > min.x && x < max.x) return true;

    x = (max.y - y1) / m + x1;
    if (x > min.x && x < max.x) return true;

    return false;
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
