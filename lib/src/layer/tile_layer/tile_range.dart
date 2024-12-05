import 'dart:math' as math hide Point;
import 'dart:math' show Point;
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// A range of tiles, this is normally a [DiscreteTileRange] and sometimes
/// a [EmptyTileRange].
@immutable
abstract class TileRange {
  /// The zoom level
  final int zoom;

  /// The base constructor the the abstract [TileRange] class.
  const TileRange(this.zoom);

  /// Get the list of coordinates for the range of tiles.
  Iterable<TileCoordinates> get coordinates;
}

/// A subclass of [TileRange] that just returns an empty [Iterable] if the
/// [coordinates] getter gets used.
@immutable
class EmptyTileRange extends TileRange {
  const EmptyTileRange._(super.zoom);

  @override
  Iterable<TileCoordinates> get coordinates =>
      const Iterable<TileCoordinates>.empty();
}

Point<int> _floor(Offset point) =>
    Point<int>(point.dx.floor(), point.dy.floor());

Point<int> _ceil(Offset point) => Point<int>(point.dx.ceil(), point.dy.ceil());

/// Every [TileRange] is a [DiscreteTileRange] if it's not an [EmptyTileRange].
@immutable
class DiscreteTileRange extends TileRange {
  /// Bounds are inclusive
  final Bounds<int> _bounds;

  /// Create a new [DiscreteTileRange] by setting it's values.
  const DiscreteTileRange(super.zoom, this._bounds);

  /// Calculate a [DiscreteTileRange] by using the pixel bounds.
  factory DiscreteTileRange.fromPixelBounds({
    required int zoom,
    required int tileDimension,
    required Rect pixelBounds,
  }) {
    final Bounds<int> bounds;
    if (pixelBounds.isEmpty) {
      final minAndMax = _floor(pixelBounds.topLeft / tileDimension.toDouble());
      bounds = Bounds<int>(minAndMax, minAndMax);
    } else {
      bounds = Bounds<int>(
        _floor(pixelBounds.topLeft / tileDimension.toDouble()),
        _ceil(pixelBounds.bottomRight / tileDimension.toDouble()) -
            const Point(1, 1),
      );
    }

    return DiscreteTileRange(zoom, bounds);
  }

  /// Expand the [DiscreteTileRange] by a given amount in every direction.
  DiscreteTileRange expand(int count) {
    if (count == 0) return this;

    return DiscreteTileRange(
      zoom,
      _bounds
          .extend(Point<int>(_bounds.min.x - count, _bounds.min.y - count))
          .extend(Point<int>(_bounds.max.x + count, _bounds.max.y + count)),
    );
  }

  /// return the [TileRange] after this tile range got intersected with an
  /// [other] tile range.
  TileRange intersect(DiscreteTileRange other) {
    final boundsIntersection = _bounds.intersect(other._bounds);

    if (boundsIntersection == null) return EmptyTileRange._(zoom);

    return DiscreteTileRange(zoom, boundsIntersection);
  }

  /// Inclusive
  TileRange intersectX(int minX, int maxX) {
    if (_bounds.min.x > maxX || _bounds.max.x < minX) {
      return EmptyTileRange._(zoom);
    }

    return DiscreteTileRange(
      zoom,
      Bounds<int>(
        Point<int>(math.max(min.x, minX), min.y),
        Point<int>(math.min(max.x, maxX), max.y),
      ),
    );
  }

  /// Inclusive
  TileRange intersectY(int minY, int maxY) {
    if (_bounds.min.y > maxY || _bounds.max.y < minY) {
      return EmptyTileRange._(zoom);
    }

    return DiscreteTileRange(
      zoom,
      Bounds<int>(
        Point<int>(min.x, math.max(min.y, minY)),
        Point<int>(max.x, math.min(max.y, maxY)),
      ),
    );
  }

  /// Check if a [Point] is inside of the bounds of the [DiscreteTileRange].
  ///
  /// We use a modulo in order to prevent side-effects at the end of the world.
  bool contains(
    Point<int> point, {
    bool replicatesWorldLongitude = false,
  }) {
    if (!replicatesWorldLongitude) {
      return _bounds.contains(point);
    }

    final int modulo = 1 << zoom;

    bool containsCoordinate(int value, int min, int max) {
      int tmp = value;
      while (tmp < min) {
        tmp += modulo;
      }
      while (tmp > max) {
        tmp -= modulo;
      }
      return tmp >= min && tmp <= max;
    }

    return containsCoordinate(point.x, min.x, max.x) &&
        containsCoordinate(point.y, min.y, max.y);
  }

  /// The minimum [Point] of the [DiscreteTileRange]
  Point<int> get min => _bounds.min;

  /// The maximum [Point] of the [DiscreteTileRange]
  Point<int> get max => _bounds.max;

  /// The center [Point] of the [DiscreteTileRange]
  Offset get center => _bounds.center;

  /// Get a list of [TileCoordinates] for the [DiscreteTileRange].
  @override
  Iterable<TileCoordinates> get coordinates sync* {
    for (var j = _bounds.min.y; j <= _bounds.max.y; j++) {
      for (var i = _bounds.min.x; i <= _bounds.max.x; i++) {
        yield TileCoordinates(i, j, zoom);
      }
    }
  }

  @override
  String toString() => 'DiscreteTileRange($min, $max)';
}
