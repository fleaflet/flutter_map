import 'dart:math';

import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:meta/meta.dart';

@immutable
abstract class TileBoundsAtZoom {
  const TileBoundsAtZoom();

  TileCoordinates wrap(TileCoordinates coordinates);

  Iterable<TileCoordinates> validCoordinatesIn(DiscreteTileRange tileRange);
}

@immutable
class InfiniteTileBoundsAtZoom extends TileBoundsAtZoom {
  const InfiniteTileBoundsAtZoom();

  @override
  TileCoordinates wrap(TileCoordinates coordinates) => coordinates;

  @override
  Iterable<TileCoordinates> validCoordinatesIn(DiscreteTileRange tileRange) =>
      tileRange.coordinates;

  @override
  String toString() => 'InfiniteTileBoundsAtZoom()';
}

@immutable
class DiscreteTileBoundsAtZoom extends TileBoundsAtZoom {
  final DiscreteTileRange tileRange;

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

@immutable
class WrappedTileBoundsAtZoom extends TileBoundsAtZoom {
  final DiscreteTileRange tileRange;
  final bool wrappedAxisIsAlwaysInBounds;
  final (int, int)? wrapX;
  final (int, int)? wrapY;

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
    return tileRange.contains(
      Point(
        _wrapInt(coordinates.x, wrapX!),
        _wrapInt(coordinates.y, wrapY!),
      ),
    );
  }

  bool _wrappedXInRange(TileCoordinates coordinates) {
    final wrappedX = _wrapInt(coordinates.x, wrapX!);
    return wrappedX >= tileRange.min.x && wrappedX <= tileRange.max.y;
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
