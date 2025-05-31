import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/native.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/size_reducer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/tile_metadata.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Isolate worker which writes tile files, and updates the size monitor,
/// synchronously
@internal
Future<void> tileAndSizeMonitorWriterWorker(
  ({
    SendPort port,
    String cacheDirectoryPath,
    String sizeMonitorFilePath,
    int? sizeLimit,
  }) input,
) async {
  final sizeMonitorFile = File(input.sizeMonitorFilePath);
  RandomAccessFile? sizeMonitor;
  late int currentSize;

  final allocatedInt64BufferForSizeMonitor = Uint8List(8);
  void updateSizeMonitor(int deltaSize) {
    if (sizeMonitor == null) return;

    currentSize += deltaSize;
    sizeMonitor!
      ..setPositionSync(0)
      ..writeFromSync(
        allocatedInt64BufferForSizeMonitor
          ..buffer.asInt64List()[0] = currentSize,
      )
      ..flushSync();
  }

  // This is called when a read failure occurs (potentially during writing),
  // usually due to corruption of a tile.
  // In this case, the size monitor cannot be made accurate without regenerating
  // it. (If a tile is truncated to 10u, we can write a fresh 50u over it,
  // but we cannot know that originally 40u were lost).
  // We don't need the monitor until the next initialisation, where we need to
  // run the size reducer, however - so we just delete it and forget about it.
  void disableSizeMonitor() {
    if (sizeMonitor == null) return;

    sizeMonitor!.closeSync();
    sizeMonitorFile.deleteSync();
    sizeMonitor = null;
  }

  // We try to open and read the size monitor, if we have a size limit.
  // If it's available, we can begin writing immediately.
  // Otherwise, we need to wait for it to be regenerated, which takes some time.
  // This is only neccessary for a brand new cache, an existing cache with a
  // newly imposed `sizeLimit` when there was previously none, or a corrupted
  // cache (where the size monitor is missing, potentially due to a read
  // failure).
  // We can run the size reducer in another isolate afterwards, as it returns a
  // relative change to the current cache size. Writes don't need to wait for
  // that expensive process.
  if (input.sizeLimit case final sizeLimit?) {
    Future<void> regenerateSizeMonitor() async {
      int calculatedSize = 0;
      int waitingForSize = 0;
      bool finishedListing = false;
      final finishedCalculating = Completer<void>();

      await for (final file in Directory(input.cacheDirectoryPath).list()) {
        if (file is! File ||
            p.basename(file.absolute.path) ==
                BuiltInMapCachingProviderImpl.sizeMonitorFileName) {
          continue;
        }
        waitingForSize++;
        file.length().then((size) {
          calculatedSize += size;
          waitingForSize--;
          if (finishedListing && waitingForSize == 0) {
            finishedCalculating.complete();
          }
        });
      }

      finishedListing = true;
      if (waitingForSize != 0) await finishedCalculating.future;

      sizeMonitor!
        ..setPositionSync(0)
        ..writeFromSync(Uint8List(8)..buffer.asInt64List()[0] = calculatedSize)
        ..flushSync();

      currentSize = calculatedSize;
    }

    final sizeMonitorInitiallyExists = sizeMonitorFile.existsSync();
    sizeMonitor = sizeMonitorFile.openSync(mode: FileMode.append)
      ..setPositionSync(0);
    if (sizeMonitorInitiallyExists) {
      try {
        currentSize = sizeMonitor!.readSync(8).buffer.asInt64List()[0];
      } catch (e) {
        await regenerateSizeMonitor();
      }
    } else {
      await regenerateSizeMonitor();
    }

    if (currentSize > sizeLimit) {
      Future<int> runSizeLimiter({
        required String cacheDirectoryPath,
        required String sizeMonitorFilePath,
        required int minSizeToDelete,
      }) =>
          Isolate.run(
            () => sizeReducerWorker(
              cacheDirectoryPath: cacheDirectoryPath,
              sizeMonitorFilePath: sizeMonitorFilePath,
              minSizeToDelete: minSizeToDelete,
            ),
          );

      runSizeLimiter(
        cacheDirectoryPath: input.cacheDirectoryPath,
        sizeMonitorFilePath: input.sizeMonitorFilePath,
        minSizeToDelete: currentSize - sizeLimit,
      ).then((deletedSize) => updateSizeMonitor(-deletedSize));
    }
  }

  final allocatedInt64Buffer = Uint8List(8);
  final allocatedUint32Buffer = Uint8List(4);
  final allocatedUint16Buffer = Uint8List(2);

  void writeTile({
    Uint8List? tileBytes,
    required final CachedMapTileMetadata metadata,
    required final String path,
  }) {
    final tileFile = File(path);
    final initialTileFileExists = tileFile.existsSync();
    final initialTileFileLength =
        initialTileFileExists ? tileFile.lengthSync() : 0;

    if (!initialTileFileExists && tileBytes == null) {
      // This should only be caused by the size reducer deleting the tile after
      // we sent it's info to the server, and it returned Not Modified correctly
      return;
    }

    if (tileBytes != null && tileBytes.lengthInBytes > 0xFFFFFFFF) {
      // These bytes are too big to have a length stored in a Uint32
      // In reality, this is unlikely
      return;
    }

    final RandomAccessFile ram;
    try {
      ram = tileFile.openSync(mode: FileMode.append);
    } on FileSystemException {
      return;
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

    // We need to read the old etag length to compare their lengths
    int? initialEtagLength;
    if (initialTileFileExists) {
      try {
        initialEtagLength = ram.readSync(2).buffer.asUint16List()[0];
      } catch (e) {
        // This implies the tile was corrupted on the previous write (the
        // write was terminated unexpectedly)
        // However, this shouldn't be possible in practise, since that should've
        // been caught on read, which should occur before every write, causing
        // a fresh overwrite with new bytes
        // We try to handle it anyway by emptying the tile completely so it is
        // auto-repaired on the next read
        ram.truncateSync(0);
        ram.closeSync();
        disableSizeMonitor();
        return;
      }

      ram.setPositionSync(16); // we need to go back to the start of the length
    }

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
              (etagBytes.lengthInBytes > 0xFFFF ? 0 : etagBytes.lengthInBytes),
      );
    }

    if (initialEtagLength != etagLength && tileBytes == null) {
      // This is annoying - even if the tile bytes haven't changed, we need to
      // rewrite them so they are in the right place
      // To do this, we have to read the remainder of the file, skipping over
      // the etag as it has not yet changed, and make it as if they were new
      // bytes
      ram.setPositionSync(18 + initialEtagLength!);

      final int initialTileBytesLength;
      try {
        initialTileBytesLength = ram.readSync(4).buffer.asUint32List()[0];
      } catch (e) {
        // This implies the tile was corrupted on the previous write (the
        // write was terminated unexpectedly)
        ram.truncateSync(0);
        ram.closeSync();
        disableSizeMonitor();
        return;
      }

      tileBytes = ram.readSync(initialTileBytesLength);
      if (tileBytes.lengthInBytes != initialTileBytesLength) {
        // This implies the tile was corrupted on the previous write (the
        // write was terminated unexpectedly whilst writing tile bytes)
        ram.truncateSync(0);
        ram.closeSync();
        disableSizeMonitor();
        return;
      }

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
      return;
    }

    // We store the length of the tile bytes in 4 bytes...
    ram.writeFromSync(
      allocatedUint32Buffer..buffer.asUint32List()[0] = tileBytes.lengthInBytes,
    );

    // ...followed by the tile bytes
    ram.writeFromSync(tileBytes);
    final finalPos = ram.positionSync();
    ram
      // We truncate the tile in case the bytes have been moved forward or are
      // shorter than previously
      ..truncateSync(finalPos)
      ..closeSync();

    // Then update the size monitor
    if (finalPos - initialTileFileLength case final deltaSize
        when deltaSize != 0) {
      updateSizeMonitor(deltaSize);
    }
  }

  // Now we're ready to recieve write messages
  final receivePort = ReceivePort();
  input.port.send(receivePort.sendPort);

  await for (final val in receivePort) {
    if (val
        case (
          :final Uint8List? tileBytes,
          :final CachedMapTileMetadata metadata,
          :final String path,
        )) {
      writeTile(path: path, metadata: metadata, tileBytes: tileBytes);
      continue;
    }
    if (val is bool && !val) {
      disableSizeMonitor();
      continue;
    }
    throw UnsupportedError(
      'Message was not in the correct format for a tile write',
    );
  }
}
