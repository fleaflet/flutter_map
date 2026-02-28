import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:meta/meta.dart';

export 'wms.dart';
export 'xyz.dart';

/// Responsible for generating a tile's 'source' ([S]), which is later used to
/// get the tile's data, given the [TileCoordinates] and ambient
/// [TileLayerOptions].
@immutable
abstract interface class SourceGenerator<S extends Object?> {
  /// Generate the 'source' ([S]) for the tile at [coordinates], with the
  /// ambient layer [options].
  S call(TileCoordinates coordinates, TileLayerOptions options);
}
