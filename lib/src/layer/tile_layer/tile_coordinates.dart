import 'dart:math';

class TileCoordinates extends Point<int> {
  final int z;

  const TileCoordinates(super.x, super.y, this.z);

  String get key => '$x:$y:$z';

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
  int get hashCode => Object.hash(x.hashCode, y.hashCode, z.hashCode);
}
