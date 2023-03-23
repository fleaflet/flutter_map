import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinate.dart';

abstract class TileRange {
  final int zoom;

  const TileRange._(this.zoom);

  Iterable<TileCoordinate> get coordinates;
}

class EmptyTileRange extends TileRange {
  const EmptyTileRange._(int zoom) : super._(zoom);

  @override
  Iterable<TileCoordinate> get coordinates =>
      const Iterable<TileCoordinate>.empty();
}

class DiscreteTileRange extends TileRange {
  // Bounds are inclusive
  final Bounds<int> _bounds;

  const DiscreteTileRange._(int zoom, this._bounds) : super._(zoom);

  factory DiscreteTileRange.fromPixelBounds({
    required int zoom,
    required CustomPoint<num> tileSize,
    required Bounds<num> pixelBounds,
  }) {
    final bounds = Bounds<int>(
      pixelBounds.min.unscaleBy(tileSize).floor().cast<int>(),
      pixelBounds.max.unscaleBy(tileSize).floor().cast<int>(),
    );

    return DiscreteTileRange._(zoom, bounds);
  }

  DiscreteTileRange expand(int count) {
    if (count == 0) return this;

    return DiscreteTileRange._(
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

    return DiscreteTileRange._(zoom, boundsIntersection);
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
}
