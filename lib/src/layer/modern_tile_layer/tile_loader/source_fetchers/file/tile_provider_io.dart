import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';

class FileBytesFetcher implements TileSourceFetcher<TileSource, Uint8List> {
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
