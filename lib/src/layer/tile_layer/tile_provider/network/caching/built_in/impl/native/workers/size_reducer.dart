import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/native.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

typedef _SizeReducerTile = ({String path, int size, DateTime sortKey});

/// Remove tile files from the cache directory until at least [minSizeToDelete]
/// bytes have been deleted.
///
/// Removes the least recently accessed tiles first. Tries to remove as few
/// tiles as possible (largest first if last accessed at same time).
///
/// Returns the number of bytes actually deleted.
@internal
Future<int> sizeReducerWorker({
  required String cacheDirectoryPath,
  required String sizeMonitorFilePath,
  required int minSizeToDelete,
}) async {
  final cacheDirectory = Directory(cacheDirectoryPath);

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
    while (deletedSize < minSizeToDelete && i < tiles.length) {
      final tile = tiles[i++];
      deletedSize += tile.size;
      yield File(tile.path).delete();
    }
  }()
      .toList(growable: false);

  await Future.wait(deletionOperations);

  return deletedSize;
}
