import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_loader.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loaders/source.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:meta/meta.dart';

/// Default implementation of a tile loader, which delegates loading of data to
/// two seperate stages:
///
///  1. The [sourceGenerator] uses a tile's [TileCoordinates] & the ambient
///     [TileLayerOptions] to generate an object, describing the tile's 'source'
///
///  2. The [sourceFetcher] uses this 'source' to generate an output data (which
///     is held within a [TileData] for the renderer's benefit)
///
/// The data ([D]) may be of any shape - but is commonly raw bytes for the
/// renderer to process. The 'source' ([S]) may be of any shape, such as
/// [TileSource].
@immutable
final class TileLoader<S extends Object?, D extends Object?>
    implements TileLoaderBase<D> {
  /// Tile source generator
  ///
  /// See documentation on [TileLoader] & [TileSourceGenerator] for information.
  final TileSourceGenerator<S> sourceGenerator;

  /// Tile source fetcher
  ///
  /// See documentation on [TileLoader] & [TileSourceFetcher] for information.
  final TileSourceFetcher<S, D> sourceFetcher;

  // TODO: Consider whether a 3rd step is useful (for converting bytes ->
  // resource), which would add better typing guarantees (tie to specific
  // renderers) - but creates more types & may be able to be best handled by the
  // renderer

  /// Create a tile loader from a source generator & fetcher
  const TileLoader({
    required this.sourceGenerator,
    required this.sourceFetcher,
  });

  @override
  TileData<D> load(TileCoordinates coordinates, TileLayerOptions options) {
    final abortTrigger = Completer<void>();
    return TileData(
      abort: abortTrigger.complete,
      data: sourceFetcher(
        sourceGenerator(coordinates, options),
        abortTrigger.future,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TileLoader &&
          other.sourceFetcher == sourceFetcher &&
          other.sourceGenerator == sourceGenerator);

  @override
  int get hashCode => Object.hash(sourceGenerator, sourceFetcher);

  /// [Uint8List] that forms a fully transparent image
  @deprecated
  static final transparentImage = Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);
}
