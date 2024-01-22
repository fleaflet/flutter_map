import 'dart:math';

import 'package:meta/meta.dart';

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
