import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/persistent_registry_parser.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/persistent_registry_writer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/size_limiter.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/workers/tile_writer_size_monitor.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

@internal
class BuiltInMapCachingProviderImpl implements BuiltInMapCachingProvider {
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
    _initialise();
  }

  static const _persistentRegistryFileName = 'registry.json';
  static const _sizeMonitorFileName = 'sizeMonitor';

  late final String _cacheDirectory;
  late final void Function(String uuid, CachedMapTileMetadata? tileInfo)
      _writeToPersistentRegistry;
  late final void Function(String tileFilePath, Uint8List? bytes)
      _writeTileFile;
  late final HashMap<String, CachedMapTileMetadata> _registry;

  Completer<void>? _isInitialised;

  @override
  bool get isSupported => true;

  @override
  Future<void> get isInitialised => _isInitialised!.future;

  Future<void> _initialise() async {
    if (_isInitialised != null) return await _isInitialised!.future;

    _isInitialised = Completer<void>();

    try {
      _cacheDirectory = p.join(
        cacheDirectory ?? (await getApplicationCacheDirectory()).absolute.path,
        'fm_cache',
      );
      final cacheDirectoryIO = Directory(_cacheDirectory);
      await cacheDirectoryIO.create(recursive: true);

      final persistentRegistryFilePath = p.join(
        _cacheDirectory,
        _persistentRegistryFileName,
      );
      final persistentRegistryFile = File(persistentRegistryFilePath);

      final sizeMonitorFilePath = p.join(
        _cacheDirectory,
        _sizeMonitorFileName,
      );

      if (await persistentRegistryFile.exists()) {
        final parsedCacheManager = await compute(
          persistentRegistryParserWorker,
          persistentRegistryFilePath,
          debugLabel: '[flutter_map: cache] Persistent Registry Parser',
        );

        if (parsedCacheManager == null) {
          await cacheDirectoryIO.delete(recursive: true);
          await cacheDirectoryIO.create(recursive: true);
          _registry = HashMap();
        } else {
          _registry = parsedCacheManager;

          if (maxCacheSize case final sizeLimit?) {
            // This can cause some delay when creating
            // But it's much better than lagging or inconsistent registries
            (await compute(
              sizeLimiterWorker,
              (
                cacheDirectoryPath: _cacheDirectory,
                persistentRegistryFileName: _persistentRegistryFileName,
                sizeMonitorFilePath: sizeMonitorFilePath,
                sizeMonitorFileName: _sizeMonitorFileName,
                sizeLimit: sizeLimit,
              ),
              debugLabel: '[flutter_map: cache] Size Limiter',
            ))
                .forEach(_registry.remove);
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
        debugName: '[flutter_map: cache] Persistent Registry Worker',
      );
      final registryWorkerSendPort =
          await registryWorkerReceivePort.first as SendPort;

      final tileFileWriterWorkerReceivePort = ReceivePort();
      await Isolate.spawn(
        tileWriterSizeMonitorWorker,
        (
          port: tileFileWriterWorkerReceivePort.sendPort,
          cacheDirectoryPath: _cacheDirectory,
          persistentRegistryFileName: _persistentRegistryFileName,
          sizeMonitorFilePath: sizeMonitorFilePath,
          sizeMonitorFileName: _sizeMonitorFileName,
        ),
        debugName: '[flutter_map: cache] Tile File Writer',
      );
      final tileFileWriterWorkerSendPort =
          await tileFileWriterWorkerReceivePort.first as SendPort;

      _writeToPersistentRegistry = (uuid, tileInfo) =>
          registryWorkerSendPort.send((uuid: uuid, tileInfo: tileInfo));
      _writeTileFile = (tileFilePath, bytes) => tileFileWriterWorkerSendPort
          .send((tileFilePath: tileFilePath, bytes: bytes));
    } catch (error, stackTrace) {
      _isInitialised!.completeError(error, stackTrace);
      rethrow;
    }

    _isInitialised!.complete();
  }

  @override
  Future<({Uint8List bytes, CachedMapTileMetadata tileInfo})?> getTile(
    String url,
  ) async {
    await isInitialised;

    final uuid = cacheKeyGenerator(url);

    final tileFile = File(p.join(_cacheDirectory, uuid));

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
            lastModifiedLocally: tileInfo.lastModifiedLocally,
            staleAt: DateTime.timestamp().add(overrideFreshAge!),
            lastModified: tileInfo.lastModified,
            etag: tileInfo.etag,
          )
        : tileInfo;

    if (_registry[uuid] case final existingTileInfo?
        when resolvedTileInfo == existingTileInfo) {
      return;
    }

    if (bytes != null) {
      final tileFilePath = p.join(_cacheDirectory, uuid);
      _writeTileFile(tileFilePath, bytes);
    }

    _registry[uuid] = resolvedTileInfo;
    _writeToPersistentRegistry(uuid, resolvedTileInfo);
  }

  Future<void> _removeTile(String uuid) async {
    await isInitialised;

    final tileFilePath = p.join(_cacheDirectory, uuid);
    _writeTileFile(tileFilePath, null);

    if (_registry.remove(uuid) == null) return;
    _writeToPersistentRegistry(uuid, null);
  }
}
