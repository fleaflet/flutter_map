import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/utils/size_monitor_opener.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

typedef _SizeLimiterTile = ({String path, int size, DateTime sortKey});

/// Remove tile files from the cache directory until the total size is below the
/// set limit
///
/// Removes the least recently accessed tiles first. Tries to remove as few
/// tiles as possible (largest first if last accessed at same time).
///
/// Returns removed tile UUIDs.
///
/// This does not alter any registries in memory.
@internal
Future<List<String>> sizeLimiterWorker(
  ({
    String cacheDirectoryPath,
    String persistentRegistryFileName,
    String sizeMonitorFilePath,
    String sizeMonitorFileName,
    int sizeLimit
  }) input,
) async {
  final cacheDirectory = Directory(input.cacheDirectoryPath);

  final (:currentSize, :sizeMonitor) = await getOrCreateSizeMonitor(
    cacheDirectoryPath: input.cacheDirectoryPath,
    persistentRegistryFileName: input.persistentRegistryFileName,
    sizeMonitorFileName: input.sizeMonitorFileName,
    sizeMonitorFilePath: input.sizeMonitorFilePath,
  );

  if (currentSize <= input.sizeLimit) {
    sizeMonitor.closeSync();
    return [];
  }

  final tiles = await Future.wait<_SizeLimiterTile>(
    cacheDirectory.listSync().whereType<File>().where((f) {
      final uuid = p.basename(f.absolute.path);
      return uuid != input.persistentRegistryFileName &&
          uuid != input.sizeMonitorFileName;
    }).map((f) async {
      final stat = await f.stat();
      // `stat.accessed` may be unstable on some OSs, but seems to work enough?
      return (path: f.absolute.path, size: stat.size, sortKey: stat.accessed);
    }),
  );

  int compareSortKeys(_SizeLimiterTile a, _SizeLimiterTile b) =>
      a.sortKey.compareTo(b.sortKey);
  int compareInverseSizes(_SizeLimiterTile a, _SizeLimiterTile b) =>
      b.size.compareTo(a.size);
  tiles.sort(compareSortKeys.then(compareInverseSizes));

  int i = 0;
  int deletedSize = 0;
  final deletedTiles = () sync* {
    while (currentSize - deletedSize > input.sizeLimit && i < tiles.length) {
      final tile = tiles[i++];
      final uuid = p.basename(tile.path);

      deletedSize += tile.size;
      yield uuid;
      yield File(tile.path).delete();
    }
  }();

  sizeMonitor
    ..setPositionSync(0)
    ..writeFromSync(
      Uint8List(8)..buffer.asInt64List()[0] = currentSize - deletedSize,
    )
    ..flushSync()
    ..closeSync();

  await Future.wait(deletedTiles.whereType<Future<FileSystemEntity>>());

  return deletedTiles.whereType<String>().toList(growable: false);
}
