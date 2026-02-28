import 'package:flutter_map/src/layer/modern_tile_layer/modern_tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';

class EmptyTileLoader implements TileLoader<WrapperTileData<void>> {
  @override
  WrapperTileData<void> call(
          TileCoordinates coordinates, TileLayerOptions options) =>
      WrapperTileData(data: null);
}
