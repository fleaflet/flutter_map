import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/independent/caching/options.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/independent/caching/tile_metadata.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'persistent_registry_workers.dart';

/// {@macro fm.mtcm}
///
/// The singleton is not disposed of. The only time it would make sense to
/// close the singleton is when either:
///  * there are no more tile providers/layers using it
///  * the app is destroyed
///
/// However, it is more difficult to track the first condition, allbeit possible.
/// More importantly, creating and opening a new instance takes some time, so
/// this should be minimized.
///
/// It is not possible to detect reliably when the process is stopped*. However,
/// we should ideally close any open file handles after we no longer need them
/// (when the singleton is disposed). Additionally, for performance, opening
/// the persistent registry file once as a [RandomAccessFile] and synchonously
/// writing to it is preferred to repeatedly opening it for async writing.
/// Therefore, a long-living isolate is used.
///
/// The isolate maintains its own in-memory registry (just as this class does
/// directly). The isolate registry and main registry should remain in sync.
/// The isolate registry is used only for writing to, which then writes
/// to the persistent registry synchronously using an open [RandomAccessFile].
/// The main registry is used only for reading and writing. The main and isolate
/// registries are populated from the persistent registry when an instance is
/// created.
///
/// When the program is terminated (or hot-reloaded in Dart), the isolate is
/// usually terminated. This usually results in the file handle being closed as
/// well. Closure of the persistent registry file is important before another
/// manager instance is created - otherwise the lock obtained will prevent
/// the new instance from working correctly. It is assumed the OS closes the
/// open file handles, but that does mean every write to the persistent
/// registry must be flushed.
///
/// A long-lasting isolate is also for writing tile files to reduce the
/// overheads of async file operations.
@immutable
class MapTileCachingManager {
  const MapTileCachingManager._({
    required String cacheDirectory,
    required void Function(String uuid, CachedMapTileMetadata? tileInfo)
        writeToPersistentRegistry,
    required void Function(String tileFilePath, Uint8List bytes) writeTileFile,
    required Map<String, CachedMapTileMetadata> registry,
  })  : _cacheDirectory = cacheDirectory,
        _writeToPersistentRegistry = writeToPersistentRegistry,
        _writeTileFile = writeTileFile,
        _registry = registry;

  static const _persistentRegistryFileName = 'manager.json';

  static Completer<MapTileCachingManager>? _instance;

  final String _cacheDirectory;
  final void Function(String uuid, CachedMapTileMetadata? tileInfo)
      _writeToPersistentRegistry;
  final void Function(String tileFilePath, Uint8List bytes) _writeTileFile;
  final Map<String, CachedMapTileMetadata> _registry;

  /// Returns an existing instance if available, else creates one and returns
  /// once ready
  ///
  /// If this is called multiple times simultanously, they will lock so that
  /// only one instance is created.
  ///
  /// Throws if an instance did not exist and could not be created. In this
  /// case, tile provider users should fallback to a non-caching implementation.
  ///
  /// If an instance is not already available, [options] is used to configure
  /// the new instance.
  static Future<MapTileCachingManager> getInstance({
    MapCachingOptions options = const MapCachingOptions(),
  }) async {
    if (_instance != null) return await _instance!.future;

    _instance = Completer();
    final MapTileCachingManager instance;

    try {
      final resolvedCacheDirectory = Directory(
        p.join(
          options.cacheDirectory ??
              (await getApplicationCacheDirectory()).absolute.path,
          'fm_cache',
        ),
      );
      await resolvedCacheDirectory.create(recursive: true);

      final persistentRegistryFilePath = p.join(
        resolvedCacheDirectory.absolute.path,
        _persistentRegistryFileName,
      );
      final persistentRegistryFile = File(persistentRegistryFilePath);

      final Map<String, CachedMapTileMetadata> registry;
      if (await persistentRegistryFile.exists()) {
        final parsedCacheManager = await compute(
          _parsePersistentRegistryWorker,
          persistentRegistryFilePath,
          debugLabel: '[flutter_map: cache] Persistent Registry Parser',
        );
        if (parsedCacheManager == null) {
          await resolvedCacheDirectory.delete(recursive: true);
          await resolvedCacheDirectory.create(recursive: true);
          await persistentRegistryFile.create(recursive: true);
          registry = HashMap();
        } else {
          registry = parsedCacheManager;

          if (options.maxCacheSize case final sizeLimit?) {
            // This can cause some delay when creating
            // But it's much better than lagging or inconsistent registries
            (await compute(
              _limitCacheSizeWorker,
              (
                cacheDirectoryPath: resolvedCacheDirectory.absolute.path,
                persistentRegistryFileName: _persistentRegistryFileName,
                sizeLimit: sizeLimit,
              ),
              debugLabel: '[flutter_map: cache] Size Limiter',
            ))
                .forEach(registry.remove);
          }
        }
      } else {
        await persistentRegistryFile.create(recursive: true);
        registry = HashMap();
      }

      final registryWorkerReceivePort = ReceivePort();
      await Isolate.spawn(
        _persistentRegistryWorkerIsolate,
        (
          port: registryWorkerReceivePort.sendPort,
          persistentRegistryFilePath: persistentRegistryFilePath,
          initialRegistry: registry,
        ),
        debugName: '[flutter_map: cache] Persistent Registry Worker',
      );
      final registryWorkerSendPort =
          await registryWorkerReceivePort.first as SendPort;

      final tileFileWriterWorkerReceivePort = ReceivePort();
      await Isolate.spawn(
        _tileFileWriterWorkerIsolate,
        tileFileWriterWorkerReceivePort.sendPort,
        debugName: '[flutter_map: cache] Tile File Writer',
      );
      final tileFileWriterWorkerSendPort =
          await tileFileWriterWorkerReceivePort.first as SendPort;

      instance = MapTileCachingManager._(
        cacheDirectory: resolvedCacheDirectory.absolute.path,
        writeToPersistentRegistry: (uuid, tileInfo) =>
            registryWorkerSendPort.send((uuid: uuid, tileInfo: tileInfo)),
        writeTileFile: (tileFilePath, bytes) => tileFileWriterWorkerSendPort
            .send((tileFilePath: tileFilePath, bytes: bytes)),
        registry: registry,
      );
    } catch (error, stackTrace) {
      _instance!.completeError(error, stackTrace);
      rethrow;
    }

    _instance!.complete(instance);
    return instance;
  }

  /// Retrieve a tile from the cache, if it exists
  Future<
      ({
        Uint8List bytes,
        CachedMapTileMetadata tileInfo,
      })?> getTile(
    String uuid,
  ) async {
    final tileFile = File(p.join(_cacheDirectory, uuid));

    if (_registry[uuid] case final tileInfo? when await tileFile.exists()) {
      return (bytes: await tileFile.readAsBytes(), tileInfo: tileInfo);
    }

    unawaited(removeTile(uuid));
    return null;
  }

  /// Add or update a tile in the cache
  ///
  /// [bytes] is required if the tile is not already cached.
  Future<void> putTile(
    String uuid,
    CachedMapTileMetadata tileInfo, [
    Uint8List? bytes,
  ]) async {
    if (_registry[uuid] case final existingTileInfo?
        when tileInfo == existingTileInfo) {
      return;
    }

    if (bytes != null) {
      final tileFilePath = p.join(_cacheDirectory, uuid);
      _writeTileFile(tileFilePath, bytes);
    }

    _registry[uuid] = tileInfo;
    _writeToPersistentRegistry(uuid, tileInfo);
  }

  /// Remove a tile from the cache
  Future<void> removeTile(String uuid) async {
    final tileFile = File(p.join(_cacheDirectory, uuid));
    if (await tileFile.exists()) await tileFile.delete();

    if (_registry.remove(uuid) == null) return;
    _writeToPersistentRegistry(uuid, null);
  }
}
