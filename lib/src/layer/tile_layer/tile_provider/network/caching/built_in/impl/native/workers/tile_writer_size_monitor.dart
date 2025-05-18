import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/utils/size_monitor_opener.dart';
import 'package:meta/meta.dart';

/// Isolate worker which writes & deletes tile files, and updates the size
/// monitor, synchronously
@internal
Future<void> tileWriterSizeMonitorWorker(
  ({
    SendPort port,
    String cacheDirectoryPath,
    String persistentRegistryFileName,
    String sizeMonitorFilePath,
    String sizeMonitorFileName,
  }) input,
) async {
  final receivePort = ReceivePort();
  input.port.send(receivePort.sendPort);

  int currentSize;
  final RandomAccessFile sizeMonitor;
  (:currentSize, :sizeMonitor) = await getOrCreateSizeMonitor(
    cacheDirectoryPath: input.cacheDirectoryPath,
    persistentRegistryFileName: input.persistentRegistryFileName,
    sizeMonitorFileName: input.sizeMonitorFileName,
    sizeMonitorFilePath: input.sizeMonitorFilePath,
  );

  final allocatedWriteBinBuffer = Uint8List(8);

  await for (final val in receivePort) {
    final (:tileFilePath, :bytes) =
        val as ({String tileFilePath, Uint8List? bytes});

    final tileFile = File(tileFilePath);
    final tileFileExists = tileFile.existsSync();

    final existingTileSize = tileFileExists ? tileFile.lengthSync() : 0;
    final newTileSize = bytes?.lengthInBytes ?? 0;
    if (newTileSize - existingTileSize case final deltaSize
        when deltaSize != 0) {
      currentSize += deltaSize;
      sizeMonitor
        ..setPositionSync(0)
        ..writeFromSync(
          allocatedWriteBinBuffer..buffer.asInt64List()[0] = currentSize,
        )
        ..flushSync();
    }

    if (bytes != null) {
      tileFile.writeAsBytesSync(bytes);
    } else if (tileFileExists) {
      tileFile.deleteSync();
    }
  }
}
