import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/tile_and_size_monitor_writer.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

@internal
class BuiltInMapCachingProviderImpl implements BuiltInMapCachingProvider {
  static const sizeMonitorFileName = 'sizeMonitor.bin';
  static const tileFileFormatSignature = [70, 77, 66, 73, 67, 84];

  final String? cacheDirectory;
  final int? maxCacheSize;
  final String Function(String url) tileKeyGenerator;
  final Duration? overrideFreshAge;
  final bool readOnly;

  final void Function() resetSingleton;

  @internal
  BuiltInMapCachingProviderImpl.create({
    required this.cacheDirectory,
    required this.maxCacheSize,
    required this.overrideFreshAge,
    required this.tileKeyGenerator,
    required this.readOnly,
    required this.resetSingleton,
  }) {
    Future<void> Function()? killWorker;
    bool earlyUninitialiseRequested = false;
    _killWorker = () {
      if (killWorker != null) return killWorker!();
      earlyUninitialiseRequested = true;
      return _cacheDirectoryPathReady.future;
    };

    () async {
      final cacheDirectoryPath = p.join(
        cacheDirectory ?? (await getApplicationCacheDirectory()).absolute.path,
        'fm_cache',
      );
      await Directory(cacheDirectoryPath).create(recursive: true);

      final sizeMonitorFilePath =
          p.join(cacheDirectoryPath, sizeMonitorFileName);

      _cacheDirectoryPath = cacheDirectoryPath;
      _cacheDirectoryPathReady.complete(cacheDirectoryPath);

      if (earlyUninitialiseRequested) return;

      SendPort? workerPort;
      final workerPortReady = Completer<SendPort>();

      // We can't send messages until the worker has set-up all the size
      // monitoring (and potentially run the reducer) if necessary
      // Reading does not depend on this.
      void sendMessageToWorker(Object? message) {
        if (workerPort != null) return workerPort!.send(message);
        workerPortReady.future.then((port) => port.send(message));
      }

      _writeTileFile = (path, metadata, tileBytes) => sendMessageToWorker(
            (path: path, metadata: metadata, tileBytes: tileBytes),
          );
      _reportReadFailure = () => sendMessageToWorker(false);

      final workerReceivePort = ReceivePort();
      final workerExited = Completer<void>();

      await Isolate.spawn(
        tileAndSizeMonitorWriterWorker,
        (
          port: workerReceivePort.sendPort,
          cacheDirectoryPath: cacheDirectoryPath,
          sizeMonitorFilePath: sizeMonitorFilePath,
          maxCacheSize: maxCacheSize,
        ),
        debugName: '[flutter_map: cache] Tile & Size Monitor Writer',
      );

      workerReceivePort.listen(
        (response) {
          if (response is SendPort && workerPort == null) {
            return workerPortReady.complete(workerPort = response);
          }
          if (response == null) {
            return workerReceivePort.close();
          }

          throw UnsupportedError('Response was in unknown format');
        },
        onDone: workerExited.complete,
      );
      killWorker = () {
        sendMessageToWorker(null);
        return workerExited.future;
      };
    }();
  }

  String? _cacheDirectoryPath; // ~cached version of below for instant access
  final _cacheDirectoryPathReady = Completer<String>();

  late final void Function(
    String path,
    CachedMapTileMetadata metadata,
    Uint8List? tileBytes,
  ) _writeTileFile;
  late final void Function()
      _reportReadFailure; // See `disableSizeMonitor` in worker
  late final Future<void> Function() _killWorker;

  final _asciiDecoder = const AsciiDecoder();

  @override
  bool get isSupported => true;

  @override
  Future<void> destroy({bool deleteCache = false}) async {
    resetSingleton();
    await _killWorker();
    if (deleteCache) {
      await Directory(_cacheDirectoryPath!).delete(recursive: true);
    }
  }

  @override
  Future<({Uint8List bytes, CachedMapTileMetadata metadata})?> getTile(
    String url,
  ) async {
    final key = tileKeyGenerator(url);
    final tileFile = File(
      p.join(_cacheDirectoryPath ?? await _cacheDirectoryPathReady.future, key),
    );

    if (!await tileFile.exists()) return null;

    try {
      final bytes = await tileFile.readAsBytes();

      if (bytes.lengthInBytes < 30) {
        throw CachedMapTileReadFailure(
          url: url,
          description: 'file was shorter than the min. expected size (found '
              '${bytes.lengthInBytes} bytes, expected >= 30 bytes)',
        );
      }

      final formatSignature = bytes.buffer.asUint8List(0, 6);

      if (formatSignature[0] != tileFileFormatSignature[0] ||
          formatSignature[1] != tileFileFormatSignature[1] ||
          formatSignature[2] != tileFileFormatSignature[2] ||
          formatSignature[3] != tileFileFormatSignature[3] ||
          formatSignature[4] != tileFileFormatSignature[4] ||
          formatSignature[5] != tileFileFormatSignature[5]) {
        throw CachedMapTileReadFailure(
          url: url,
          description:
              'file did not contain expected format signature at start (found '
              '$formatSignature, expected $tileFileFormatSignature)',
        );
      }

      final version = bytes.buffer.asUint16List(6, 1)[0];

      if (version != 1) {
        throw CachedMapTileReadFailure(
          url: url,
          description:
              'cache file was of a different version (found v$version, '
              'expected v1)',
        );
      }

      final timestamps = bytes.buffer.asInt64List(8, 2);
      final staleAt =
          DateTime.fromMillisecondsSinceEpoch(timestamps[0], isUtc: true);
      final lastModified = timestamps[1] == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(timestamps[1], isUtc: true);

      final etagLength = bytes.buffer.asUint16List(24, 1)[0];
      final String? etag;
      if (etagLength == 0) {
        etag = null;
      } else {
        final etagBytes = Uint8List.sublistView(bytes, 26, 26 + etagLength);
        etag = _asciiDecoder.convert(etagBytes);
      }

      final tileBytesExpectedLength = // Perform an unaligned read
          bytes.buffer.asByteData(26 + etagLength, 4).getUint32(0, Endian.host);
      // We read the remainder of the file, rather than just reading the
      // specified number of bytes
      final tileBytes = Uint8List.sublistView(bytes, 26 + etagLength + 4);
      if (tileBytes.lengthInBytes != tileBytesExpectedLength) {
        throw CachedMapTileReadFailure(
          url: url,
          description: 'tile image bytes were not of expected length (found '
              '${tileBytes.lengthInBytes} bytes, expected '
              '$tileBytesExpectedLength bytes)',
        );
      }

      return (
        metadata: CachedMapTileMetadata(
          staleAt: staleAt,
          lastModified: lastModified,
          etag: etag,
        ),
        bytes: tileBytes,
      );
    } on CachedMapTileReadFailure {
      _reportReadFailure();
      rethrow;
    } catch (error, stackTrace) {
      _reportReadFailure();
      Error.throwWithStackTrace(
        CachedMapTileReadFailure(url: url, originalError: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata metadata,
    Uint8List? bytes,
  }) async {
    if (readOnly) return;

    final key = tileKeyGenerator(url);
    final path = p.join(
      _cacheDirectoryPath ?? await _cacheDirectoryPathReady.future,
      key,
    );

    _writeTileFile(
      path,
      overrideFreshAge != null
          ? CachedMapTileMetadata(
              staleAt: DateTime.timestamp().add(overrideFreshAge!),
              lastModified: metadata.lastModified,
              etag: metadata.etag,
            )
          : metadata,
      bytes,
    );
  }
}
