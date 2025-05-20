import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/persistent_registry_unpacker.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/persistent_registry_writer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/size_limiter.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/tile_writer_size_monitor.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/utils/size_monitor_opener.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

@internal
class BuiltInMapCachingProviderImpl implements BuiltInMapCachingProvider {
  static const persistentRegistryFileName = 'registry.json';
  static const sizeMonitorFileName = 'sizeMonitor.bin';

  final String? cacheDirectory;
  final int? maxCacheSize;
  final Duration? overrideFreshAge;
  final String Function(String url) cacheKeyGenerator;
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
        _cacheDirectoryPath = p.join(
          this.cacheDirectory ??
              (await getApplicationCacheDirectory()).absolute.path,
          'fm_cache',
        );
        final cacheDirectory = Directory(_cacheDirectoryPath);
        await cacheDirectory.create(recursive: true);

        final persistentRegistryFilePath =
            p.join(_cacheDirectoryPath, persistentRegistryFileName);
        final persistentRegistryFile = File(persistentRegistryFilePath);

        final sizeMonitorFilePath =
            p.join(_cacheDirectoryPath, sizeMonitorFileName);

        if (await persistentRegistryFile.exists()) {
          final parsedCacheManager = await compute(
            persistentRegistryUnpackerWorker,
            persistentRegistryFilePath,
            debugLabel: '[flutter_map: cache] Persistent Registry Unpacker',
          );

          if (parsedCacheManager == null) {
            await cacheDirectory.delete(recursive: true);
            await cacheDirectory.create(recursive: true);
            _registry = HashMap();
          } else {
            _registry = parsedCacheManager;

            if (maxCacheSize case final sizeLimit?) {
              final currentSize =
                  await asyncGetOnlySizeMonitor(sizeMonitorFilePath);

              if (currentSize == null || currentSize > sizeLimit) {
                (await compute(
                  sizeLimiterWorker,
                  (
                    cacheDirectoryPath: _cacheDirectoryPath,
                    sizeMonitorFilePath: sizeMonitorFilePath,
                    sizeLimit: sizeLimit,
                  ),
                  debugLabel: '[flutter_map: cache] Size Limiter',
                ))
                    .forEach(_registry.remove);
              }
            }
          }
        } else {
          _registry = HashMap();
        }

        final registryWorkerReceivePort = ReceivePort();
        await Isolate.spawn(
          persistentRegistryWriterWorker,
          (
            port: registryWorkerReceivePort.sendPort,
            persistentRegistryFilePath: persistentRegistryFilePath,
            initialRegistry: _registry,
          ),
          debugName: '[flutter_map: cache] Persistent Registry Writer',
        );
        final registryWorkerSendPort =
            await registryWorkerReceivePort.first as SendPort;

        final tileFileWriterWorkerReceivePort = ReceivePort();
        await Isolate.spawn(
          tileWriterSizeMonitorWorker,
          (
            port: tileFileWriterWorkerReceivePort.sendPort,
            cacheDirectoryPath: _cacheDirectoryPath,
            sizeMonitorFilePath: sizeMonitorFilePath,
          ),
          debugName: '[flutter_map: cache] Tile File & Size Monitor Writer',
        );
        final tileFileWriterWorkerSendPort =
            await tileFileWriterWorkerReceivePort.first as SendPort;

        _writeToPersistentRegistry = (uuid, tileInfo) =>
            registryWorkerSendPort.send((uuid: uuid, tileInfo: tileInfo));
        _writeTileFile = (tileFilePath, bytes) => tileFileWriterWorkerSendPort
            .send((tileFilePath: tileFilePath, bytes: bytes));

        return _registry.length;
      }(),
    );
  }

  late final String _cacheDirectoryPath;
  late final void Function(String uuid, CachedMapTileMetadata? tileInfo)
      _writeToPersistentRegistry;
  late final void Function(String tileFilePath, Uint8List? bytes)
      _writeTileFile;
  late final HashMap<String, CachedMapTileMetadata> _registry;

  final _isInitialised = Completer<int>();
  @override
  Future<int> get isInitialised => _isInitialised.future;

  @override
  bool get isSupported => true;

  @override
  Future<({Uint8List bytes, CachedMapTileMetadata tileInfo})?> getTile(
    String url,
  ) async {
    await isInitialised;

    final uuid = cacheKeyGenerator(url);
    final tileFile = File(p.join(_cacheDirectoryPath, uuid));

    if (_registry[uuid] case final tileInfo? when await tileFile.exists()) {
      return (bytes: await tileFile.readAsBytes(), tileInfo: tileInfo);
    }

    unawaited(_removeTile(uuid));
    return null;
  }

  @override
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata tileInfo,
    Uint8List? bytes,
  }) async {
    if (readOnly) return;

    await isInitialised;

    final uuid = cacheKeyGenerator(url);
    final resolvedTileInfo = overrideFreshAge != null
        ? CachedMapTileMetadata(
            staleAt: DateTime.timestamp().add(overrideFreshAge!),
            lastModified: tileInfo.lastModified,
            etag: tileInfo.etag,
          )
        : tileInfo;

    if (bytes != null) {
      final tileFilePath = p.join(_cacheDirectoryPath, uuid);
      _writeTileFile(tileFilePath, bytes);
    }

    _registry[uuid] = resolvedTileInfo;
    _writeToPersistentRegistry(uuid, resolvedTileInfo);
  }

  Future<void> _removeTile(String uuid) async {
    await isInitialised;

    final tileFilePath = p.join(_cacheDirectoryPath, uuid);
    _writeTileFile(tileFilePath, null);

    if (_registry.remove(uuid) == null) return;
    _writeToPersistentRegistry(uuid, null);
  }
}
