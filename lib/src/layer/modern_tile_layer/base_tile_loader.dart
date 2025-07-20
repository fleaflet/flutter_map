import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_loader.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:meta/meta.dart';

/// Responsible for generating data ([D]) for tiles given the tile's
/// [TileCoordinates] and ambient [TileLayerOptions].
///
/// See [TileLoader] for an implementation which delegates its responsibility
/// into two parts.
@immutable
abstract interface class BaseTileLoader<D extends BaseTileData> {
  /// Generate data for the tile at [coordinates], with the ambient layer
  /// [options].
  D call(TileCoordinates coordinates, TileLayerOptions options);
}
