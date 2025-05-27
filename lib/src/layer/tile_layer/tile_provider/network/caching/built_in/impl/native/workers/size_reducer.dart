import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/native.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/utils/size_monitor_opener.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

typedef _SizeReducerTile = ({String path, int size, DateTime sortKey});

/// Remove tile files from the cache directory until the total size is below the
/// set limit
///
/// Removes the least recently accessed tiles first. Tries to remove as few
/// tiles as possible (largest first if last accessed at same time).
///
/// Returns the number of bytes deleted.
@internal
Future<int> sizeReducerWorker(
  ({
    String cacheDirectoryPath,
    String sizeMonitorFilePath,
    int sizeLimit,
  }) input,
) async {
  final cacheDirectory = Directory(input.cacheDirectoryPath);

  final (:currentSize, :sizeMonitor) = await getOrCreateSizeMonitor(
    cacheDirectoryPath: input.cacheDirectoryPath,
    sizeMonitorFilePath: input.sizeMonitorFilePath,
  );
  sizeMonitor.closeSync();

  if (currentSize <= input.sizeLimit) return 0;

  final tiles = await Future.wait<_SizeReducerTile>(
    cacheDirectory.listSync().whereType<File>().where((f) {
      final uuid = p.basename(f.absolute.path);
      return uuid != BuiltInMapCachingProviderImpl.sizeMonitorFileName;
    }).map((f) async {
      final stat = await f.stat();
      // `stat.accessed` may be unstable on some OSs, but seems to work enough?
      return (path: f.absolute.path, size: stat.size, sortKey: stat.accessed);
    }),
  );

  int compareSortKeys(_SizeReducerTile a, _SizeReducerTile b) =>
      a.sortKey.compareTo(b.sortKey);
  int compareInverseSizes(_SizeReducerTile a, _SizeReducerTile b) =>
      b.size.compareTo(a.size);
  tiles.sort(compareSortKeys.then(compareInverseSizes));

  int i = 0;
  int deletedSize = 0;
  final deletionOperations = () sync* {
    while (currentSize - deletedSize > input.sizeLimit && i < tiles.length) {
      final tile = tiles[i++];
      deletedSize += tile.size;
      yield File(tile.path).delete();
    }
  }()
      .toList(growable: false);

  await Future.wait(deletionOperations);

  return deletedSize;
}
