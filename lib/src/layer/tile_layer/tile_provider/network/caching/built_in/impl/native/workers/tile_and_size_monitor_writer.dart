import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/utils/size_monitor_opener.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/tile_metadata.dart';
import 'package:meta/meta.dart';

/// Isolate worker which writes tile files, and updates the size monitor,
/// synchronously
@internal
Future<void> tileAndSizeMonitorWriterWorker(
  ({
    SendPort port,
    String cacheDirectoryPath,
    String sizeMonitorFilePath,
  }) input,
) async {
  final receivePort = ReceivePort();
  input.port.send(receivePort.sendPort);

  int currentSize;
  final RandomAccessFile sizeMonitor;
  (:currentSize, :sizeMonitor) = await getOrCreateSizeMonitor(
    cacheDirectoryPath: input.cacheDirectoryPath,
    sizeMonitorFilePath: input.sizeMonitorFilePath,
  );

  void updateSizeMonitor(int deltaSize) {
    currentSize += deltaSize;
    sizeMonitor
      ..setPositionSync(0)
      ..writeFromSync(Uint8List(8)..buffer.asInt64List()[0] = currentSize)
      ..flushSync();
  }

  final allocatedInt64Buffer = Uint8List(8);
  final allocatedUint16Buffer = Uint8List(2);

  await for (final val in receivePort) {
    if (val is int) {
      updateSizeMonitor(-val);
      continue;
    }

    Uint8List? tileBytes;
    final CachedMapTileMetadata metadata;
    final String path;
    (:tileBytes, :metadata, :path) = val as ({
      Uint8List? tileBytes,
      CachedMapTileMetadata metadata,
      String path
    });

    final tileFile = File(path);
    final initialTileFileExists = tileFile.existsSync();
    final initialTileFileLength =
        initialTileFileExists ? tileFile.lengthSync() : 0;

    if (!initialTileFileExists && tileBytes == null) {
      // This could be caused by:
      //  * the tile server responding with a Not Modified status code
      //    incorrectly
      //  * the size reducer deleting the tile after we sent it's info to the
      //    server, and it returned Not Modified correctly
      continue;
    }

    final RandomAccessFile ram;
    try {
      ram = tileFile.openSync(mode: FileMode.append);
    } on FileSystemException {
      continue;
    }

    ram
      // We start reading from the start of the file, where we store our header
      // info
      ..setPositionSync(0)
      // We store the stale-at header in 8 bytes...
      ..writeFromSync(
        allocatedInt64Buffer
          ..buffer.asInt64List()[0] = metadata.staleAtMilliseconds,
      )
      // ...followed by the last-modified header in 8 bytes, or '0' if null
      ..writeFromSync(
        allocatedInt64Buffer
          ..buffer.asInt64List()[0] = metadata.lastModifiedMilliseconds ?? 0,
      );

    final initialEtagLength =
        initialTileFileExists ? ram.readSync(2).buffer.asUint16List()[0] : null;
    ram.setPositionSync(16); // we need to go back to the start of the length
    final int etagLength;
    late final Uint8List etagBytes; // left unset if etagLength = 0
    if (metadata.etag == null) {
      // We don't have an etag, so we write 2 bytes indicating the etag length
      // is 0
      ram.writeFromSync(
        allocatedUint16Buffer..buffer.asUint16List()[0] = etagLength = 0,
      );
    } else {
      etagBytes = const AsciiEncoder().convert(metadata.etag!);
      // We store the etag length in 2 bytes...
      // (unless it is too large)
      ram.writeFromSync(
        allocatedUint16Buffer
          ..buffer.asUint16List()[0] = etagLength =
              (etagBytes.lengthInBytes > 65535 ? 0 : etagBytes.lengthInBytes),
      );
    }

    if (initialEtagLength != etagLength && tileBytes == null) {
      // This is annoying - even if the tile bytes haven't changed, we need to
      // rewrite them so they are in the right place
      // To do this, we have to read the remainder of the file, skipping over
      // the etag as it has not yet changed, and make it as if they were new
      // bytes
      ram.setPositionSync(18 + initialEtagLength!);
      tileBytes = ram.readSync(9223372036854775807); // to the end of the file
      ram.setPositionSync(18);
    }

    if (etagLength != 0) {
      // ...followed by the etag itself
      ram.writeFromSync(etagBytes);
    }

    if (tileBytes == null) {
      // If there were no updates to the tile bytes, that also implies there
      // were no changes to the length of the etag, so we don't need to do
      // any size updates
      ram.closeSync();
      continue;
    }

    // We write the new tile bytes to the file and truncate it to the end
    ram.writeFromSync(tileBytes);
    final finalPos = ram.positionSync();
    ram
      ..truncateSync(ram.positionSync())
      ..closeSync();

    // Then update the size monitor
    if (finalPos - initialTileFileLength case final deltaSize
        when deltaSize != 0) {
      updateSizeMonitor(deltaSize);
    }
  }
}
