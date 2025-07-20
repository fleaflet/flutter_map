import 'dart:typed_data';

import 'package:flutter_map/src/layer/modern_tile_layer/base_tile_loader.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/options.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_data.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:meta/meta.dart';

/// Default implementation of a tile loader, which delegates loading of data to
/// two seperate stages:
///
///  1. The [sourceGenerator] uses a tile's [TileCoordinates] & the ambient
///     [TileLayerOptions] to generate an object, describing the tile's 'source'
///     ([S])
///
///  2. The [sourceFetcher] uses this 'source' to generate an output [TileData]
///     ([D])
@immutable
final class TileLoader<S extends Object?, D extends TileData>
    implements BaseTileLoader<D> {
  /// Tile source generator.
  ///
  /// See documentation on [TileLoader] & [TileSourceGenerator] for information.
  final TileSourceGenerator<S> sourceGenerator;

  /// Tile source fetcher.
  ///
  /// See documentation on [TileLoader] & [TileSourceFetcher] for information.
  final TileSourceFetcher<S, D> sourceFetcher;

  /// Create a tile loader from a source generator & fetcher.
  const TileLoader({
    required this.sourceGenerator,
    required this.sourceFetcher,
  });

  @override
  D load(TileCoordinates coordinates, TileLayerOptions options) =>
      sourceFetcher(sourceGenerator(coordinates, options));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TileLoader &&
          other.sourceFetcher == sourceFetcher &&
          other.sourceGenerator == sourceGenerator);

  @override
  int get hashCode => Object.hash(sourceGenerator, sourceFetcher);

  /// [Uint8List] that forms a fully transparent image.
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
