import 'dart:math';

import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// Tile coordinates identify the position of the tile position for
/// slippy map tiles. The z coordinate represents the zoom level where the
/// zoom level of 0 fits the complete world while bigger z values are using
/// accordingly to the zoom level of the [MapCamera].
///
/// For more information see the docs https://docs.fleaflet.dev/getting-started/explanation#slippy-map-convention.
///
/// The tile coordinates are based on maths' [Point] class but extended with
/// the zoom level.
@immutable
class TileCoordinates extends Point<int> {
  /// The zoom level of the tile coordinates.
  final int z;

  /// Create a new [TileCoordinates] instance.
  const TileCoordinates(super.x, super.y, this.z);

  @override
  String toString() => 'TileCoordinate($x, $y, $z)';

  // Overridden because Point's distanceTo does not allow comparing with a point
  // of a different type.
  @override
  double distanceTo(Point<num> other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TileCoordinates &&
        other.x == x &&
        other.y == y &&
        other.z == z;
  }

  @override
  int get hashCode {
    // NOTE: the odd numbers are due to JavaScript's integer precision of 53 bits.
    return x ^ y << 24 ^ z << 48;
  }
}

/// Resolves coordinates in the context of world replications.
///
/// On maps with world replications, different tile coordinates may actually
/// refer to the same "resolved" tile coordinate - the coordinate that starts
/// from 0.
/// For instance, on zoom level 0, all tile coordinates can be simplified to
/// (0,0), which is the only tile.
/// On zoom level 1, (0, 1) and (2, 1) can be simplified to (0, 1), as they both
/// mean the bottom left tile.
/// And when we're not in the context of world replications, we don't have to
/// simplify the tile coordinates: we just return the same value.
class TileCoordinatesResolver {
  /// Resolves coordinates in the context of world replications.
  const TileCoordinatesResolver(
    this.replicatesWorldLongitude, {
    this.zoomOffset = 0,
  });

  /// True if we simplify the coordinates according to the world replications.
  final bool replicatesWorldLongitude;

  /// The zoom number used for modulus will be offset with this value.
  final int zoomOffset;

  /// Returns the simplification of the coordinates.
  TileCoordinates get(TileCoordinates positionCoordinates) {
    if (!replicatesWorldLongitude) {
      return positionCoordinates;
    }
    if (positionCoordinates.z < 0) {
      return positionCoordinates;
    }
    final modulo = 1 << (positionCoordinates.z + zoomOffset);
    int x = positionCoordinates.x;
    while (x < 0) {
      x += modulo;
    }
    while (x >= modulo) {
      x -= modulo;
    }
    int y = positionCoordinates.y;
    while (y < 0) {
      y += modulo;
    }
    while (y >= modulo) {
      y -= modulo;
    }
    return TileCoordinates(x, y, positionCoordinates.z);
  }
}
