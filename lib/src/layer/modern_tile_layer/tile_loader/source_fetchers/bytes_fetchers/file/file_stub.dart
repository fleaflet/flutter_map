import 'package:flutter/foundation.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_source.dart';

@immutable
class FileBytesFetcher implements TileBytesFetcher<TileSource> {
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
