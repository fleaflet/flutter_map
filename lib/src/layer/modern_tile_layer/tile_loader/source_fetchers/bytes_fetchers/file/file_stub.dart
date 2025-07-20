import 'dart:async';

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
  }) {
    throw UnsupportedError(
      '`FileBytesFetcher` is unsupported on non-native platforms',
    );
  }
}
