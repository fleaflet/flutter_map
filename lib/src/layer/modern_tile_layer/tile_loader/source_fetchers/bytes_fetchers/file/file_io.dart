import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/bytes_fetcher.dart';

/// A [SourceBytesFetcher] which fetches from the local filesystem.
///
/// {@macro fm.sbf.default.sourceConsumption}
@immutable
class FileBytesFetcher implements SourceBytesFetcher<Iterable<String>> {
  /// A [SourceBytesFetcher] which fetches from the local filesystem.
  const FileBytesFetcher();

  @override
  Future<R> call<R>({
    required Iterable<String> source,
    required Future<void> abortSignal,
    required BytesToResourceTransformer<R> transformer,
  }) async {
    final iterator = source.iterator;

    if (!iterator.moveNext()) {
      throw ArgumentError('At least one URI must be provided', 'source');
    }

    for (bool isPrimary = true;; isPrimary = false) {
      // TODO: Consider abortable streaming of bytes
      try {
        return await transformer(
          await File(iterator.current).readAsBytes(),
          // In fallback scenarios, we never allow reuse of bytes in the
          // short-term cache (or long-term cache)
          allowReuse: isPrimary,
        );
      } on Exception {
        if (!iterator.moveNext()) rethrow; // No (more) fallbacks available

        // Attempt fallbacks
        // TODO: Consider logging
        continue;
      }
    }
  }
}
