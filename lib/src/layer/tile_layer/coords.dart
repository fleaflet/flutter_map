import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/util.dart' as util;
import 'package:tuple/tuple.dart';

class Coords<T extends num> extends CustomPoint<T> {
  late T z;

  Coords(T x, T y) : super(x, y);

  Coords<double> wrap(
      Tuple2<double, double>? wrapX, Tuple2<double, double>? wrapY) {
    final newCoords = Coords<double>(
      wrapX != null ? util.wrapNum(x.toDouble(), wrapX) : x.toDouble(),
      wrapY != null ? util.wrapNum(y.toDouble(), wrapY) : y.toDouble(),
    );
    newCoords.z = z.toDouble();
    return newCoords;
  }

  String get key => '$x:$y:$z';

  @override
  String toString() => 'Coords($x, $y, $z)';

  @override
  bool operator ==(Object other) {
    if (other is Coords) {
      return x == other.x && y == other.y && z == other.z;
    }
    return false;
  }

  @override
  int get hashCode => hashValues(x.hashCode, y.hashCode, z.hashCode);
}
