import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/flatbufs/registry.g.dart';
import 'package:meta/meta.dart';

/// Isolate worker which maintains its own registry and sequences writes to
/// the persistent registry
///
/// We cannot use [IOSink] from [File.openWrite], since we need to overwrite the
/// entire file on every write. [RandomAccessFile] allows this, and may also be
/// faster (especially for sync operations). However, it does not sequence
/// writes as [IOSink] does: attempting multiple writes at the same time throws
/// errors. If we use sync operations on every incoming update, this shouldn't
/// be an issue - instead, we use a debouncer (at 50ms, which is small enough
/// that the user should not usually terminate the isolate very close to loading
/// tiles, but also small enough to group adjacent tile loads), so manual
/// sequencing and locking is required.
@internal
Future<void> persistentRegistryWriterWorker(
  ({
    SendPort port,
    String persistentRegistryFilePath,
    Map<String, CachedMapTileMetadata> initialRegistry,
  }) input,
) async {
  final receivePort = ReceivePort();
  input.port.send(receivePort.sendPort);

  final registry = input.initialRegistry;
  final writer =
      File(input.persistentRegistryFilePath).openSync(mode: FileMode.writeOnly);

  var writeLocker = Completer<void>()..complete();
  var alreadyWaitingToWrite = false;
  Future<void> write() async {
    if (alreadyWaitingToWrite) return;
    alreadyWaitingToWrite = true;
    await writeLocker.future;
    writeLocker = Completer();
    alreadyWaitingToWrite = false;

    _writeFlatbuffer(registry, writer);

    writeLocker.complete();
  }

  Timer createWriteDebouncer() =>
      Timer(const Duration(milliseconds: 50), write);
  Timer? writeDebouncer;

  write();

  await for (final val in receivePort) {
    final (:uuid, :tileInfo) =
        val as ({String uuid, CachedMapTileMetadata? tileInfo});

    if (tileInfo == null) {
      registry.remove(uuid);
    } else {
      registry[uuid] = tileInfo;
    }

    writeDebouncer?.cancel();
    writeDebouncer = createWriteDebouncer();
  }
}

void _writeFlatbuffer(
  Map<String, CachedMapTileMetadata> registry,
  RandomAccessFile fileWriter,
) {
  final registryIds = registry.keys.toList(growable: false);
  final registryMetadatas = registry.values.toList(growable: false);

  final builder = fb.Builder(initialSize: 1048576);

  final entriesOffset = builder.writeList(
    List.generate(
      registry.length,
      (i) {
        final id = registryIds[i];
        final metadata = registryMetadatas[i];

        final fbId = builder.writeString(id, asciiOptimization: true);
        final fbEtag = metadata.etag == null
            ? null
            : builder.writeString(metadata.etag!, asciiOptimization: true);

        final fbTileMetadata = (TileMetadataBuilder(builder)
              ..begin()
              ..addLastModifiedLocally(
                metadata.lastModifiedLocally.millisecondsSinceEpoch,
              )
              ..addStaleAt(metadata.staleAt.millisecondsSinceEpoch)
              ..addEtagOffset(fbEtag)
              ..addLastModified(metadata.lastModified?.millisecondsSinceEpoch))
            .finish();

        return (TileMetadataEntryBuilder(builder)
              ..begin()
              ..addIdOffset(fbId)
              ..addMetadataOffset(fbTileMetadata))
            .finish();
      },
      growable: false,
    ),
  );

  final metadataMapOffset = (TileMetadataMapBuilder(builder)
        ..begin()
        ..addEntriesOffset(entriesOffset))
      .finish();

  builder.finish(metadataMapOffset);

  fileWriter
    ..setPositionSync(0)
    ..writeFromSync(builder.buffer)
    ..truncateSync(fileWriter.positionSync())
    ..flushSync();
}
