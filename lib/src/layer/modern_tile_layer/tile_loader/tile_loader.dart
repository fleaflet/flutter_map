import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:meta/meta.dart';

/// Responsible for generating a tile's data ([D]), given the [TileCoordinates]
/// and ambient [TileLayerOptions].
@immutable
abstract interface class TileLoader<D extends BaseTileData> {
  /// Generate data ([D]) for the tile at [coordinates], with the ambient layer
  /// [options].
  D call(TileCoordinates coordinates, TileLayerOptions options);
}
