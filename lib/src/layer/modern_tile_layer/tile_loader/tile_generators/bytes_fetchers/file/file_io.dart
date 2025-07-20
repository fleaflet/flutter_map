import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_generators/bytes_fetchers/bytes_fetcher.dart';

/// A [SourceBytesFetcher] which fetches a URI from the local filesystem.
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
  }) =>
      fetchFromSourceIterable(
        (uri, transformer, isFirst) =>
            File(uri).readAsBytes().then(transformer),
        source: source,
        transformer: transformer,
      );
}
