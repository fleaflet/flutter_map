import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinate.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:tuple/tuple.dart';

abstract class TileBoundsAtZoom {
  const TileBoundsAtZoom();

  TileCoordinate wrap(TileCoordinate coordinate);

  Iterable<TileCoordinate> validCoordinatesIn(DiscreteTileRange tileRange);
}

class InfiniteTileBoundsAtZoom extends TileBoundsAtZoom {
  const InfiniteTileBoundsAtZoom();

  @override
  TileCoordinate wrap(TileCoordinate coordinate) => coordinate;

  @override
  Iterable<TileCoordinate> validCoordinatesIn(DiscreteTileRange tileRange) =>
      tileRange.coordinates;

  @override
  String toString() => 'InfiniteTileBoundsAtZoom()';
}

class DiscreteTileBoundsAtZoom extends TileBoundsAtZoom {
  final DiscreteTileRange tileRange;

  const DiscreteTileBoundsAtZoom(this.tileRange);

  @override
  TileCoordinate wrap(TileCoordinate coordinate) => coordinate;

  @override
  Iterable<TileCoordinate> validCoordinatesIn(DiscreteTileRange tileRange) {
    assert(this.tileRange.zoom == tileRange.zoom);
    return this.tileRange.intersect(tileRange).coordinates;
  }

  @override
  String toString() => 'DiscreteTileBoundsAtZoom($tileRange)';
}

class WrappedTileBoundsAtZoom extends TileBoundsAtZoom {
  final DiscreteTileRange tileRange;
  final bool wrappedAxisIsAlwaysInBounds;
  final Tuple2<int, int>? wrapX;
  final Tuple2<int, int>? wrapY;

  const WrappedTileBoundsAtZoom({
    required this.tileRange,
    // If true the wrapped axis will not be checked when calling
    // validCoordinatesIn. This makes sense if the [tileRange] is from the crs
    // since with wrapping enabled all tiles on that axis should be valid. For
    // a user defined [tileRange] this should be false as some tiles may fall
    // outside of the range.
    required this.wrappedAxisIsAlwaysInBounds,
    // Inclusive range to which x coordinates will be wrapped.
    required this.wrapX,
    // Inclusive range to which y coordinates will be wrapped.
    required this.wrapY,
  }) : assert(!(wrapX == null && wrapY == null));

  @override
  TileCoordinate wrap(TileCoordinate coordinate) => TileCoordinate(
        wrapX != null ? _wrapInt(coordinate.x, wrapX!) : coordinate.x,
        wrapY != null ? _wrapInt(coordinate.y, wrapY!) : coordinate.y,
        coordinate.z,
      );

  @override
  Iterable<TileCoordinate> validCoordinatesIn(DiscreteTileRange tileRange) {
    if (wrapX != null && wrapY != null) {
      if (wrappedAxisIsAlwaysInBounds) return tileRange.coordinates;

      // We need to wrap and check each coordinate.
      return tileRange.coordinates.where(_wrappedBothContains);
    } else if (wrapX != null) {
      // wrapY is null otherwise this would be a discrete bounds
      // We can intersect the y coordinate since its not wrapped
      final intersectedRange = tileRange.intersectY(
        this.tileRange.min.y,
        this.tileRange.max.y,
      );
      if (wrappedAxisIsAlwaysInBounds) return intersectedRange.coordinates;
      return intersectedRange.coordinates.where(_wrappedXInRange);
    } else if (wrapY != null) {
      // wrapX is null otherwise this would be a discrete bounds
      // We can intersect the x coordinate since its not wrapped
      final intersectedRange = tileRange.intersectX(
        this.tileRange.min.x,
        this.tileRange.max.x,
      );
      if (wrappedAxisIsAlwaysInBounds) return intersectedRange.coordinates;
      return intersectedRange.coordinates.where(_wrappedYInRange);
    } else {
      throw "Wrapped bounds must wrap on at least one axis";
    }
  }

  bool _wrappedBothContains(TileCoordinate coordinate) {
    return tileRange.contains(
      CustomPoint(
        _wrapInt(coordinate.x, wrapX!),
        _wrapInt(coordinate.y, wrapY!),
      ),
    );
  }

  bool _wrappedXInRange(TileCoordinate coordinate) {
    final wrappedX = _wrapInt(coordinate.x, wrapX!);
    return wrappedX >= tileRange.min.x && wrappedX <= tileRange.max.y;
  }

  bool _wrappedYInRange(TileCoordinate coordinate) {
    final wrappedY = _wrapInt(coordinate.y, wrapY!);
    return wrappedY >= tileRange.min.y && wrappedY <= tileRange.max.y;
  }

  /// Wrap [x] to be within [range] inclusive.
  int _wrapInt(int x, Tuple2<int, int> range) {
    final d = range.item2 + 1 - range.item1;
    return ((x - range.item1) % d + d) % d + range.item1;
  }

  @override
  String toString() =>
      'WrappedTileBoundsAtZoom($tileRange, $wrappedAxisIsAlwaysInBounds, $wrapX, $wrapY)';
}
