import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_layer.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:meta/meta.dart';

/// Responsible for generating a tile's data ([D]), given the [TileCoordinates]
/// and ambient [TileLayerOptions].
///
/// Once a tile has been generated, it is passed to the [BaseTileLayer.renderer]
/// for rendering.
@immutable
abstract interface class TileLoader<D extends BaseTileData> {
  /// Generate data ([D]) for the tile at [coordinates], with the ambient layer
  /// [options].
  ///
  /// The data must be generated synchronously. However, the interface of
  /// [BaseTileData] allows for integration of asynchronous work with the tile
  /// layer.
  ///
  /// If this throws an error then the tile will not be rendered.
  D call(TileCoordinates coordinates, TileLayerOptions options);
}
