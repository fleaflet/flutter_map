import 'dart:math';

import 'package:meta/meta.dart';

@immutable
class TileCoordinates extends Point<int> {
  final int z;

  const TileCoordinates(super.x, super.y, this.z);

  String get key => '$x:$y:$z';

  @override
  String toString() => 'TileCoordinate($x, $y, $z)';

  @override
  bool operator ==(Object other) {
    if (other is! TileCoordinates) return false;

    return x == other.x && y == other.y && z == other.z;
  }

  // Overriden because Point's distanceTo does not allow comparing with a point
  // of a different type.
  @override
  double distanceTo(Point<num> other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  int get hashCode => Object.hash(x.hashCode, y.hashCode, z.hashCode);
}
