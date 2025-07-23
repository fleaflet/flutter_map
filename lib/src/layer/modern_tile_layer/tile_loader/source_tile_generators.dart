import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_generators/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:meta/meta.dart';

/// Generates a tile's 'source' based on its own properties, the ambient
/// [TileLayerOptions], and the tile's [TileCoordinates].
///
/// The source type must be consumable by the [TileGenerator] used.
@immutable
abstract interface class SourceGenerator<S extends Object?> {
  /// Generates a tile's 'source' based on its own properties, the ambient
  /// [TileLayerOptions], and the tile's [TileCoordinates].
  ///
  /// See documentation on [SourceGenerator] for more information.
  S call(TileCoordinates coordinates, TileLayerOptions options);
}

/// Generates a tile's data ([D]) based on its 'source' ([S]).
///
/// The source type is set by the [SourceGenerator]. The fetcher does not have
/// access to the ambient [TileLayerOptions], therefore any required options
/// must appear in the source.
///
/// To promote flexibility and re-usability, it is recommended to further
/// delegate parts of the tile generator, such as I/O fetching operations. It
/// may depend on a [SourceBytesFetcher] to do this.
@immutable
abstract interface class TileGenerator<S extends Object?,
    D extends BaseTileData> {
  /// Generates a tile's data ([D]) based on its 'source' ([S]).
  ///
  /// See documentation on [TileGenerator] for more information.
  D call(S source);
}
