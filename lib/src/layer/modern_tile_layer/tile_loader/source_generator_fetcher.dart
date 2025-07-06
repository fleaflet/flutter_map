import 'dart:async';

import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:meta/meta.dart';

/// Generates a tile's 'source' based on its own properties, the ambient
/// [TileLayerOptions], and the tile's [TileCoordinates]
///
/// The 'source' type must be consumable by the [TileSourceFetcher] used.
///
/// If this generator accepts other properties/options, it must remain immutable
/// and must set a valid equality operator.
@immutable
abstract interface class TileSourceGenerator<S extends Object?> {
  /// Generates a tile's 'source'
  ///
  /// See documentation on [TileSourceGenerator] for more information.
  S call(TileCoordinates coordinates, TileLayerOptions options);
}

/// Fetch a tile's data based on its 'source' ([S])
///
/// A tile's data ([T]) is often bytes. These may be interpreted by a tile
/// layer's renderer. However, this is not required - it may be preferable to
/// perform some (potentially asynchronous) processing of data before sending it
/// to the renderer.
///
/// The 'source' type is set by the [TileSourceGenerator]. The fetcher does not
/// have access to the ambient [TileLayerOptions], therefore any required
/// options must appear in the 'source'.
///
/// Supports an abort signal to abort an ongoing operation, such as a network
/// request. It is not required to respect the signal.
///
/// If this fetcher accepts other properties/options, it must remain immutable
/// and must set a valid equality operator.
@immutable
abstract interface class TileSourceFetcher<S extends Object?,
    T extends Object?> {
  /// Fetch a tile's data based on its 'source'
  ///
  /// See documentation on [TileSourceFetcher] for more information.
  FutureOr<T> call(S source, Future<void> abortSignal);
}
