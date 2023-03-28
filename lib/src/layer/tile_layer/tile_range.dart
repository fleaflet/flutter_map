import 'dart:math' as math;

import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinate.dart';

abstract class TileRange {
  final int zoom;

  const TileRange(this.zoom);

  Iterable<TileCoordinate> get coordinates;
}

class EmptyTileRange extends TileRange {
  const EmptyTileRange._(super.zoom);

  @override
  Iterable<TileCoordinate> get coordinates =>
      const Iterable<TileCoordinate>.empty();
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
      final minAndMax = (pixelBounds.min / tileSize).floor().cast<int>();
      bounds = Bounds<int>(minAndMax, minAndMax);
    } else {
      bounds = Bounds<int>(
        (pixelBounds.min / tileSize).floor().cast<int>(),
        (pixelBounds.max / tileSize).ceil().cast<int>() -
            const CustomPoint(1, 1),
      );
    }

    return DiscreteTileRange(zoom, bounds);
  }

  DiscreteTileRange expand(int count) {
    if (count == 0) return this;

    return DiscreteTileRange(
      zoom,
      _bounds
          .extend(
            CustomPoint<int>(_bounds.min.x - count, _bounds.min.y - count),
          )
          .extend(
            CustomPoint<int>(_bounds.max.x + count, _bounds.max.y + count),
          ),
    );
  }

  TileRange intersect(DiscreteTileRange other) {
    final boundsIntersection = _bounds.intersect(other._bounds);

    if (boundsIntersection == null) return EmptyTileRange._(zoom);

    return DiscreteTileRange(zoom, boundsIntersection);
  }

  // Inclusive
  TileRange intersectX(int minX, int maxX) {
    if (_bounds.min.x > maxX || _bounds.max.x < minX) {
      return EmptyTileRange._(zoom);
    }

    return DiscreteTileRange(
      zoom,
      Bounds(
        CustomPoint(math.max(min.x, minX), min.y),
        CustomPoint(math.min(max.x, maxX), max.y),
      ),
    );
  }

  // Inclusive
  TileRange intersectY(int minY, int maxY) {
    if (_bounds.min.y > maxY || _bounds.max.y < minY) {
      return EmptyTileRange._(zoom);
    }

    return DiscreteTileRange(
      zoom,
      Bounds(
        CustomPoint(min.x, math.max(min.y, minY)),
        CustomPoint(max.x, math.min(max.y, maxY)),
      ),
    );
  }

  bool contains(CustomPoint<int> point) {
    return _bounds.contains(point);
  }

  CustomPoint<int> get min => _bounds.min;

  CustomPoint<int> get max => _bounds.max;

  CustomPoint<double> get center => _bounds.center;

  @override
  Iterable<TileCoordinate> get coordinates sync* {
    for (var j = _bounds.min.y; j <= _bounds.max.y; j++) {
      for (var i = _bounds.min.x; i <= _bounds.max.x; i++) {
        yield TileCoordinate(i, j, zoom);
      }
    }
  }

  @override
  String toString() => 'DiscreteTileRange($min, $max)';
}
