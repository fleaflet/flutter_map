import 'dart:io';
import 'dart:typed_data';

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
  ) async {
    try {
      return await File(source.uri).readAsBytes();
    } on FileSystemException {
      if (source.fallbackUri == null) rethrow;
      return await File(source.fallbackUri!).readAsBytes();
    }
  }
}
