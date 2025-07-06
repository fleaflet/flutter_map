import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_data.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:meta/meta.dart';

@immutable
abstract interface class TileLoaderBase<D extends Object?> {
  const TileLoaderBase();

  TileData<D> load(TileCoordinates coordinates, TileLayerOptions options);

  @override
  @mustBeOverridden
  int get hashCode;

  @override
  @mustBeOverridden
  bool operator ==(Object other);
}
