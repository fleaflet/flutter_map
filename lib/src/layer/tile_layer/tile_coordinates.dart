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

  /// Returns a unique value for the same tile on all world replications.
  factory TileCoordinates.key(TileCoordinates coordinates) {
    if (coordinates.z < 0) {
      return coordinates;
    }
    final modulo = 1 << coordinates.z;
    int x = coordinates.x;
    while (x < 0) {
      x += modulo;
    }
    while (x >= modulo) {
      x -= modulo;
    }
    int y = coordinates.y;
    while (y < 0) {
      y += modulo;
    }
    while (y >= modulo) {
      y -= modulo;
    }
    return TileCoordinates(x, y, coordinates.z);
  }

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
