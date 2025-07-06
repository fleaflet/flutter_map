import 'package:flutter/foundation.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';

class FileBytesFetcher implements TileSourceFetcher<TileSource, Uint8List> {
  const FileBytesFetcher();

  @override
  Future<Uint8List> call(
    TileSource source,
    Future<void> abortSignal,
  ) {
    throw UnsupportedError(
      '`FileBytesFetcher` is unsupported on non-native platforms',
    );
  }
}
