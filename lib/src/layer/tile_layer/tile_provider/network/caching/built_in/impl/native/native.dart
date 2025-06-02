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

  final String? cacheDirectory;
  final int? maxCacheSize;
  final String Function(String url) tileKeyGenerator;
  final Duration? overrideFreshAge;
  final bool readOnly;

  @internal
  BuiltInMapCachingProviderImpl.createAndInitialise({
    required this.cacheDirectory,
    required this.maxCacheSize,
    required this.overrideFreshAge,
    required this.tileKeyGenerator,
    required this.readOnly,
  }) {
    // This should only be called/constructed once
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

      SendPort? writerPort;
      final writerPortReady = Completer<SendPort>();

      // We can't send messages until the worker has set-up all the size
      // monitoring (and potentially run the reducer) if necessary
      // Reading does not depend on this.
      void sendMessageToWriter(Object message) {
        if (writerPort != null) return writerPort.send(message);
        writerPortReady.future.then((port) => port.send(message));
      }

      _writeTileFile = (path, metadata, tileBytes) => sendMessageToWriter(
            (path: path, metadata: metadata, tileBytes: tileBytes),
          );
      _reportReadFailure = () => sendMessageToWriter(false);

      final writerReceivePort = ReceivePort();
      await Isolate.spawn(
        tileAndSizeMonitorWriterWorker,
        (
          port: writerReceivePort.sendPort,
          cacheDirectoryPath: cacheDirectoryPath,
          sizeMonitorFilePath: sizeMonitorFilePath,
          maxCacheSize: maxCacheSize,
        ),
        debugName: '[flutter_map: cache] Tile & Size Monitor Writer',
      );

      writerPort = await writerReceivePort.first as SendPort;
      writerPortReady.complete(writerPort);
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

  @override
  bool get isSupported => true;

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

      if (bytes.lengthInBytes < 22) {
        throw CachedMapTileReadFailure(
          url: url,
          description:
              'cache file (${bytes.lengthInBytes}) was shorter than the '
              'minimum expected size',
        );
      }

      final firstTwoNums = bytes.buffer.asInt64List(0, 2);
      final staleAt =
          DateTime.fromMillisecondsSinceEpoch(firstTwoNums[0], isUtc: true);
      final lastModified = firstTwoNums[1] == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(firstTwoNums[1], isUtc: true);

      final etagLength = bytes.buffer.asUint16List(16, 1)[0];
      final String? etag;
      if (etagLength == 0) {
        etag = null;
      } else {
        final etagBytes = Uint8List.sublistView(bytes, 18, 18 + etagLength);
        etag = const AsciiDecoder().convert(etagBytes);
      }

      final tileBytesExpectedLength = // Perform an unaligned read
          bytes.buffer.asByteData(18 + etagLength, 4).getUint32(0, Endian.host);

      final tileBytes = Uint8List.sublistView(bytes, 18 + etagLength + 4);

      if (tileBytes.lengthInBytes != tileBytesExpectedLength) {
        throw CachedMapTileReadFailure(
          url: url,
          description:
              'tile image bytes (${tileBytes.lengthInBytes}) were not of '
              'expected length ($tileBytesExpectedLength)',
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
