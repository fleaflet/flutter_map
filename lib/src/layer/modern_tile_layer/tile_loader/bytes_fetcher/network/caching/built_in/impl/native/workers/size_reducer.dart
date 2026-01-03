import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/bytes_fetcher/network/caching/built_in/impl/native/native.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

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

  final tiles = await Future.wait(
    cacheDirectory.listSync().whereType<File>().where((f) {
      final uuid = p.basename(f.absolute.path);
      return uuid != BuiltInMapCachingProviderImpl.sizeMonitorFileName;
    }).map((f) async {
      // `stat.accessed` may be unstable on some OSs, but seems to work enough?
      final stat = await f.stat();

      return _SizeReducerTile(
        path: f.absolute.path,
        size: stat.size,
        sortKey: stat.accessed,
      );
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
      yield File(tile.path).delete().then((_) {}, onError: (_) {
        // We might not be able to delete the tile if its being read/just been
        // read, because "another process" has obtained a lock on the tile.
        // (jaffaketchup) (it's difficult to prove whether this is the case, but
        // it makes sense)
        // This could be seen as a useful feature: the tiles which the user sees
        // when they start the app remain cached.
        // In reality, this is unlikely to occur unless the size limit is really
        // small (since other older tiles will be deleted first, which shouldn't
        // be locked).
        // This silences the error.
      });
    }
  }()
      .toList(growable: false);

  await Future.wait(deletionOperations);

  return deletedSize;
}

@immutable
class _SizeReducerTile {
  final String path; // We assume the path is unique for equality purposes
  final int size;
  final DateTime sortKey;

  const _SizeReducerTile({
    required this.path,
    required this.size,
    required this.sortKey,
  });

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _SizeReducerTile && other.path == path);
}
