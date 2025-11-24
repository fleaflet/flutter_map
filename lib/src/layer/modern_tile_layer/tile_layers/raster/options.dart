import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

@immutable
class RasterTileLayerOptions {
  const RasterTileLayerOptions({this.crs});

  final Crs? crs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RasterTileLayerOptions && crs == other.crs);

  @override
  int get hashCode => Object.hash(crs, null);
}
