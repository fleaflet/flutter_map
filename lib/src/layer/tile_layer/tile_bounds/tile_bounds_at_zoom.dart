import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:meta/meta.dart';

/// A bounding box with zoom level.
@immutable
abstract class TileBoundsAtZoom {
  /// Create a new [TileBoundsAtZoom] object.
  const TileBoundsAtZoom();

  /// Wrap [TileCoordinates] for the tile bounds.
  TileCoordinates wrap(TileCoordinates coordinates);

  /// Returns a list of [TileCoordinates] that are valid because they are within
  /// the [TileRange].
  Iterable<TileCoordinates> validCoordinatesIn(DiscreteTileRange tileRange);
}

/// A infinite tile bounding box.
@immutable
class InfiniteTileBoundsAtZoom extends TileBoundsAtZoom {
  /// Create a new [InfiniteTileBoundsAtZoom] object.
  const InfiniteTileBoundsAtZoom();

  @override
  TileCoordinates wrap(TileCoordinates coordinates) => coordinates;

  @override
  Iterable<TileCoordinates> validCoordinatesIn(DiscreteTileRange tileRange) =>
      tileRange.coordinates;

  @override
  String toString() => 'InfiniteTileBoundsAtZoom()';
}

/// [TileBoundsAtZoom] that have discrete coordinate bounds.
@immutable
class DiscreteTileBoundsAtZoom extends TileBoundsAtZoom {
  /// The [TileRange] of the [TileBoundsAtZoom].
  final DiscreteTileRange tileRange;

  /// Create a new [DiscreteTileBoundsAtZoom] object.
  const DiscreteTileBoundsAtZoom(this.tileRange);

  @override
  TileCoordinates wrap(TileCoordinates coordinates) => coordinates;

  @override
  Iterable<TileCoordinates> validCoordinatesIn(DiscreteTileRange tileRange) {
    assert(
      this.tileRange.zoom == tileRange.zoom,
      "The zoom of the provided TileRange can't differ from the zoom level of the current tileRange",
    );
    return this.tileRange.intersect(tileRange).coordinates;
  }

  @override
  String toString() => 'DiscreteTileBoundsAtZoom($tileRange)';
}

/// A bounding box with zoom level that gets wrapped
@immutable
class WrappedTileBoundsAtZoom extends TileBoundsAtZoom {
  /// The range of tiles for the bounding box.
  final DiscreteTileRange tileRange;

  /// If true the wrapped axis will not be checked when calling
  /// validCoordinatesIn. This makes sense if the [tileRange] is from the crs
  /// since with wrapping enabled all tiles on that axis should be valid. For
  /// a user defined [tileRange] this should be false as some tiles may fall
  /// outside of the range.
  final bool wrappedAxisIsAlwaysInBounds;

  /// Inclusive range to which x coordinates will be wrapped.
  final (int, int)? wrapX;

  /// Inclusive range to which y coordinates will be wrapped.
  final (int, int)? wrapY;

  /// Create a new [WrappedTileBoundsAtZoom] object.
  const WrappedTileBoundsAtZoom({
    required this.tileRange,
    required this.wrappedAxisIsAlwaysInBounds,
    required this.wrapX,
    required this.wrapY,
  }) : assert(
          wrapX != null || wrapY != null,
          'Either wrapX or wrapY needs to be not null',
        );

  @override
  TileCoordinates wrap(TileCoordinates coordinates) => TileCoordinates(
        wrapX != null ? _wrapInt(coordinates.x, wrapX!) : coordinates.x,
        wrapY != null ? _wrapInt(coordinates.y, wrapY!) : coordinates.y,
        coordinates.z,
      );

  @override
  Iterable<TileCoordinates> validCoordinatesIn(DiscreteTileRange tileRange) {
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
      throw Exception('Wrapped bounds must wrap on at least one axis');
    }
  }

  bool _wrappedBothContains(TileCoordinates coordinates) {
    return tileRange.contains(TileCoordinates(
      _wrapInt(coordinates.x, wrapX!),
      _wrapInt(coordinates.y, wrapY!),
      coordinates.z,
    ));
  }

  bool _wrappedXInRange(TileCoordinates coordinates) {
    final wrappedX = _wrapInt(coordinates.x, wrapX!);
    return wrappedX >= tileRange.min.x && wrappedX <= tileRange.max.x;
  }

  bool _wrappedYInRange(TileCoordinates coordinates) {
    final wrappedY = _wrapInt(coordinates.y, wrapY!);
    return wrappedY >= tileRange.min.y && wrappedY <= tileRange.max.y;
  }

  /// Wrap [x] to be within [range] inclusive.
  int _wrapInt(int x, (int, int) range) {
    final d = range.$2 + 1 - range.$1;
    return ((x - range.$1) % d + d) % d + range.$1;
  }

  @override
  String toString() =>
      'WrappedTileBoundsAtZoom($tileRange, $wrappedAxisIsAlwaysInBounds, $wrapX, $wrapY)';
}
