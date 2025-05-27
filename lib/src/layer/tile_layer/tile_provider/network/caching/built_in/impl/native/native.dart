import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/size_reducer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/tile_and_size_monitor_writer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/utils/size_monitor_opener.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/data.dart';
import 'package:uuid/rng.dart';
import 'package:uuid/uuid.dart';

@internal
class BuiltInMapCachingProviderImpl implements BuiltInMapCachingProvider {
  static const sizeMonitorFileName = 'sizeMonitor.bin';

  final String? cacheDirectory;
  final int? maxCacheSize;
  final Duration? overrideFreshAge;
  final String Function(String url)? cacheKeyGenerator;
  final bool readOnly;

  @internal
  BuiltInMapCachingProviderImpl.createAndInitialise({
    required this.cacheDirectory,
    required this.maxCacheSize,
    required this.overrideFreshAge,
    required this.cacheKeyGenerator,
    required this.readOnly,
  }) {
    // This should only be called/constructed once
    _isInitialised.complete(
      () async {
        if (cacheKeyGenerator == null) {
          _uuid = Uuid(goptions: GlobalOptions(MathRNG()));
        }

        _cacheDirectoryPath = p.join(
          this.cacheDirectory ??
              (await getApplicationCacheDirectory()).absolute.path,
          'fm_cache',
        );
        final cacheDirectory = Directory(_cacheDirectoryPath);
        await cacheDirectory.create(recursive: true);

        final sizeMonitorFilePath =
            p.join(_cacheDirectoryPath, sizeMonitorFileName);

        final tileAndSizeMonitorWriterWorkerReceivePort = ReceivePort();
        await Isolate.spawn(
          tileAndSizeMonitorWriterWorker,
          (
            port: tileAndSizeMonitorWriterWorkerReceivePort.sendPort,
            cacheDirectoryPath: _cacheDirectoryPath,
            sizeMonitorFilePath: sizeMonitorFilePath,
          ),
          debugName: '[flutter_map: cache] Tile & Size Monitor Writer',
        );
        final tileAndSizeMonitorWriterWorkerReceivePortSendPort =
            await tileAndSizeMonitorWriterWorkerReceivePort.first as SendPort;
        _writeTileFile = ({required path, required metadata, tileBytes}) =>
            tileAndSizeMonitorWriterWorkerReceivePortSendPort
                .send((path: path, metadata: metadata, tileBytes: tileBytes));

        if (maxCacheSize case final sizeLimit?) {
          () async {
            final currentSize =
                await asyncGetOnlySizeMonitor(sizeMonitorFilePath);

            if (currentSize == null || currentSize > sizeLimit) {
              final deletedSize = await compute(
                sizeReducerWorker,
                (
                  cacheDirectoryPath: _cacheDirectoryPath,
                  sizeMonitorFilePath: sizeMonitorFilePath,
                  sizeLimit: sizeLimit,
                ),
                debugLabel: '[flutter_map: cache] Size Reducer',
              );

              if (deletedSize == 0) return;
              tileAndSizeMonitorWriterWorkerReceivePortSendPort
                  .send(deletedSize);
            }
          }();
        }
      }(),
    );
  }

  late final String _cacheDirectoryPath;
  late final Uuid _uuid; // left un-inited if provided generator
  late final void Function({
    required String path,
    required CachedMapTileMetadata metadata,
    Uint8List? tileBytes,
  }) _writeTileFile;

  final _isInitialised = Completer<void>();
  @override
  Future<void> get isInitialised => _isInitialised.future;

  @override
  bool get isSupported => true;

  @override
  Future<({Uint8List bytes, CachedMapTileMetadata metadata})?> getTile(
    String url,
  ) async {
    await isInitialised;

    final key =
        cacheKeyGenerator?.call(url) ?? _uuid.v5(Namespace.url.value, url);
    final tileFile = File(p.join(_cacheDirectoryPath, key));

    if (!await tileFile.exists()) return null;

    final bytes = await tileFile.readAsBytes();

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

    final tileBytes = Uint8List.sublistView(bytes, 18 + etagLength);

    return (
      metadata: CachedMapTileMetadata(
        staleAt: staleAt,
        lastModified: lastModified,
        etag: etag,
      ),
      bytes: tileBytes,
    );
  }

  @override
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata metadata,
    Uint8List? bytes,
  }) async {
    if (readOnly) return;

    await isInitialised;

    final key =
        cacheKeyGenerator?.call(url) ?? _uuid.v5(Namespace.url.value, url);
    final path = p.join(_cacheDirectoryPath, key);

    final resolvedMetadata = overrideFreshAge != null
        ? CachedMapTileMetadata(
            staleAt: DateTime.timestamp().add(overrideFreshAge!),
            lastModified: metadata.lastModified,
            etag: metadata.etag,
          )
        : metadata;

    _writeTileFile(path: path, metadata: resolvedMetadata, tileBytes: bytes);
  }
}
