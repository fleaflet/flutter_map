import 'dart:math' as math hide Point;
import 'dart:math' show Point;

import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/misc/point_extensions.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';

abstract class TileRange {
  final int zoom;

  const TileRange(this.zoom);

  Iterable<TileCoordinates> get coordinates;
}

class EmptyTileRange extends TileRange {
  const EmptyTileRange._(super.zoom);

  @override
  Iterable<TileCoordinates> get coordinates =>
      const Iterable<TileCoordinates>.empty();
}

class DiscreteTileRange extends TileRange {
  // Bounds are inclusive
  final Bounds<int> _bounds;

  const DiscreteTileRange(super.zoom, this._bounds);

  factory DiscreteTileRange.fromPixelBounds({
    required int zoom,
    required double tileSize,
    required Bounds<num> pixelBounds,
  }) {
    final Bounds<int> bounds;
    if (pixelBounds.min == pixelBounds.max) {
      final minAndMax = (pixelBounds.min / tileSize).floor();
      bounds = Bounds<int>(minAndMax, minAndMax);
    } else {
      bounds = Bounds<int>(
        (pixelBounds.min / tileSize).floor(),
        (pixelBounds.max / tileSize).ceil() - const Point(1, 1),
      );
    }

    return DiscreteTileRange(zoom, bounds);
  }

  DiscreteTileRange expand(int count) {
    if (count == 0) return this;

    return DiscreteTileRange(
      zoom,
      _bounds
          .extend(Point<int>(_bounds.min.x - count, _bounds.min.y - count))
          .extend(Point<int>(_bounds.max.x + count, _bounds.max.y + count)),
    );
  }

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
      Bounds(
        Point(math.max(min.x, minX), min.y),
        Point(math.min(max.x, maxX), max.y),
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
      Bounds(
        Point(min.x, math.max(min.y, minY)),
        Point(max.x, math.min(max.y, maxY)),
      ),
    );
  }

  bool contains(Point<int> point) {
    return _bounds.contains(point);
  }

  Point<int> get min => _bounds.min;

  Point<int> get max => _bounds.max;

  Point<double> get center => _bounds.center;

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
