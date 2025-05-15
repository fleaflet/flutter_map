import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_map/flutter_map.dart';
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
  final registry = input.initialRegistry;
  final writer =
      File(input.persistentRegistryFilePath).openSync(mode: FileMode.writeOnly);

  // We rewrite the registry from the initial state in-case it was size limited,
  // for example
  final encoded = jsonEncode(registry);
  writer
    ..writeStringSync(encoded)
    ..truncateSync(writer.positionSync())
    ..flushSync();

  var writeLocker = Completer<void>()..complete();
  var alreadyWaitingToWrite = false;
  Future<void> write() async {
    if (alreadyWaitingToWrite) return;
    alreadyWaitingToWrite = true;
    await writeLocker.future;
    writeLocker = Completer();
    alreadyWaitingToWrite = false;

    final encoded = jsonEncode(registry);
    writer
      ..setPositionSync(0)
      ..writeStringSync(encoded)
      ..truncateSync(writer.positionSync())
      ..flushSync();

    writeLocker.complete();
  }

  Timer createWriteDebouncer() =>
      Timer(const Duration(milliseconds: 50), write);
  Timer? writeDebouncer;

  final receivePort = ReceivePort();
  input.port.send(receivePort.sendPort);

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
