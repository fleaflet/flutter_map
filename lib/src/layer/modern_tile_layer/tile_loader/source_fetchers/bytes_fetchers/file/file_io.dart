import 'dart:io';

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
    bool useFallback = false,
  }) async {
    final resolvedUri = useFallback ? source.fallbackUri ?? '' : source.uri;

    try {
      final bytes = await File(resolvedUri).readAsBytes();
      return await transformer(bytes);
    } on Exception {
      if (useFallback || source.fallbackUri == null) rethrow;
      return this(
        source: source,
        abortSignal: abortSignal,
        // In fallback scenarios, we never reuse bytes
        transformer: (bytes, {allowReuse = true}) =>
            transformer(bytes, allowReuse: false),
        useFallback: useFallback,
      );
    }
  }
}
