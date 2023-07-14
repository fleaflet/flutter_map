import 'dart:math' as math;
import 'dart:math';

/// Rectangular bound delimited by orthogonal lines passing through two
/// points.
class Bounds<T extends num> {
  final Point<T> min;
  final Point<T> max;

  const Bounds._(this.min, this.max);

  factory Bounds(Point<T> a, Point<T> b) {
    final bounds1 = Bounds._(a, b);
    final bounds2 = bounds1.extend(a);
    return bounds2.extend(b);
  }

  static Bounds<double> containing(Iterable<Point<double>> points) {
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    var minX = double.infinity;
    var minY = double.infinity;

    for (final point in points) {
      if (point.x > maxX) {
        maxX = point.x;
      }
      if (point.x < minX) {
        minX = point.x;
      }
      if (point.y > maxY) {
        maxY = point.y;
      }
      if (point.y < minY) {
        minY = point.y;
      }
    }

    final bounds = Bounds._(
      Point(minX, minY),
      Point(maxX, maxY),
    );

    return bounds;
  }

  /// Creates a new [Bounds] obtained by expanding the current ones with a new
  /// point.
  Bounds<T> extend(Point<T> point) {
    return Bounds._(
      Point(
        math.min(point.x, min.x),
        math.min(point.y, min.y),
      ),
      Point(
        math.max(point.x, max.x),
        math.max(point.y, max.y),
      ),
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

  bool contains(Point<T> point) {
    final min = point;
    final max = point;
    return containsBounds(Bounds(min, max));
  }

  bool containsBounds(Bounds<T> b) {
    return (b.min.x >= min.x) &&
        (b.max.x <= max.x) &&
        (b.min.y >= min.y) &&
        (b.max.y <= max.y);
  }

  bool containsPartialBounds(Bounds<T> b) {
    return (b.min.x <= max.x) &&
        (b.max.x >= min.x) &&
        (b.min.y <= max.y) &&
        (b.max.y >= min.y);
  }

  // Calculates the intersection of two Bounds. The return value will be null
  // if there is no intersection. The returned bounds may be zero size
  // (bottomLeft == topRight).
  Bounds<T>? intersect(Bounds<T> b) {
    final leftX = math.max(min.x, b.min.x);
    final rightX = math.min(max.x, b.max.x);
    final topY = math.max(min.y, b.min.y);
    final bottomY = math.min(max.y, b.max.y);

    if (leftX <= rightX && topY <= bottomY) {
      return Bounds(Point(leftX, topY), Point(rightX, bottomY));
    }

    return null;
  }

  @override
  String toString() => 'Bounds($min, $max)';
}
