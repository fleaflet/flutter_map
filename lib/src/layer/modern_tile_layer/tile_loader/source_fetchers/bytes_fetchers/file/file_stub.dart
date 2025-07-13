import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_source.dart';

/// A [SourceBytesFetcher] which fetches from the local filesystem, based on
/// their [TileSource]
@immutable
class FileBytesFetcher implements SourceBytesFetcher<TileSource> {
  /// A [SourceBytesFetcher] which fetches from the local filesystem, based on
  /// their [TileSource]
  const FileBytesFetcher();

  @override
  Future<R> call<R>({
    required TileSource source,
    required Future<void> abortSignal,
    required BytesToResourceTransformer<R> transformer,
  }) {
    throw UnsupportedError(
      '`FileBytesFetcher` is unsupported on non-native platforms',
    );
  }
}
