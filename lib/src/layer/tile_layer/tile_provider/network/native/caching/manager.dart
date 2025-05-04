import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/independent/caching/options.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'persistent_registry_workers.dart';
part 'tile_information.dart';

/// Singleton class which manages built-in tile caching on native platforms
///
/// Built-in tile caching is simple and based on the tile's HTTP headers.
///
/// > [!IMPORTANT]
/// > Built-in tile caching is not a replacement for caching which can better
/// > guarantee resilience. It should not solely be used where not having
/// > cached tiles may lead to a dangerous situation - for example, offline
/// > mapping. This provides no guarantees as to the safety of cached tiles.
///
/// By default, caching is performed in a caching directory set by the OS, which
/// may be cleared at any time.
///
/// The registry used to manage tiles is in JSON. There is no guarantee that the
/// registry will remain valid (not corrupt). A corrupt registry will result in
/// all cached tiles being lost.
///
/// Tile server URLs which use (for example) API keys create tiles with UUIDs
/// including the volatile part of the URL. If this part of the URL is changed,
/// all tiles previously stored will become in-accessible.
///
/// The cache does not peristently monitor usage (eg. hits) of the cache.
///
/// The primary purpose of this caching is to reduce the number of requests
/// to tile servers.
///
/// ---
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
// TODO: Expose for other providers? How to expose without breaking IO boundary?
@immutable
class MapTileCachingManager {
  const MapTileCachingManager._({
    required String cacheDirectory,
    required void Function(String uuid, CachedTileInformation? tileInfo)
        writeToPersistentRegistry,
    required void Function(String tileFilePath, Uint8List bytes) writeTileFile,
    required Map<String, CachedTileInformation> registry,
  })  : _cacheDirectory = cacheDirectory,
        _writeToPersistentRegistry = writeToPersistentRegistry,
        _writeTileFile = writeTileFile,
        _registry = registry;

  static const _persistentRegistryFileName = 'manager.json';

  static MapTileCachingManager? _instance;
  static bool _instanceBeingCreated = false;

  final String _cacheDirectory;
  final void Function(String uuid, CachedTileInformation? tileInfo)
      _writeToPersistentRegistry;
  final void Function(String tileFilePath, Uint8List bytes) _writeTileFile;
  final Map<String, CachedTileInformation> _registry;

  /// Returns the current instance if one is already available; otherwise, start
  /// creating a new instance in the background and return `null`
  ///
  /// This will also return null if an instance is already being created in the
  /// background but is not ready yet, or if one could not be created (for
  /// example due to an error when attempting to create the instance).
  ///
  /// [options] is only used to configure a new instance. If [options] changes,
  /// a new instance will not be created.
  static MapTileCachingManager? getInstanceOrCreate({
    required MapCachingOptions options,
  }) {
    if (_instance != null) return _instance!;

    if (_instanceBeingCreated) return null;
    _instanceBeingCreated = true;

    () async {
      final Directory resolvedCacheDirectory;
      try {
        resolvedCacheDirectory = Directory(
          p.join(
            options.cacheDirectory ??
                (await getApplicationCacheDirectory()).absolute.path,
            'fm_cache',
          ),
        );
      } on MissingPlatformDirectoryException {
        return null;
      }

      try {
        await resolvedCacheDirectory.create(recursive: true);
      } on FileSystemException {
        return null;
      }

      final persistentRegistryFilePath = p.join(
        resolvedCacheDirectory.absolute.path,
        _persistentRegistryFileName,
      );
      final persistentRegistryFile = File(persistentRegistryFilePath);

      final Map<String, CachedTileInformation> registry;
      try {
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
      } on FileSystemException {
        return null;
      }

      final registryWorkerReceivePort = ReceivePort();
      try {
        await Isolate.spawn(
          _persistentRegistryWorkerIsolate,
          (
            port: registryWorkerReceivePort.sendPort,
            persistentRegistryFilePath: persistentRegistryFilePath,
            initialRegistry: registry,
          ),
          debugName: '[flutter_map: cache] Persistent Registry Worker',
        );
      } catch (e) {
        return null;
      }
      final registryWorkerSendPort =
          await registryWorkerReceivePort.first as SendPort;

      final tileFileWriterWorkerReceivePort = ReceivePort();
      try {
        await Isolate.spawn(
          _tileFileWriterWorkerIsolate,
          tileFileWriterWorkerReceivePort.sendPort,
          debugName: '[flutter_map: cache] Tile File Writer',
        );
      } catch (e) {
        return null;
      }
      final tileFileWriterWorkerSendPort =
          await tileFileWriterWorkerReceivePort.first as SendPort;

      _instance = MapTileCachingManager._(
        cacheDirectory: resolvedCacheDirectory.absolute.path,
        writeToPersistentRegistry: (uuid, tileInfo) =>
            registryWorkerSendPort.send((uuid: uuid, tileInfo: tileInfo)),
        writeTileFile: (tileFilePath, bytes) => tileFileWriterWorkerSendPort
            .send((tileFilePath: tileFilePath, bytes: bytes)),
        registry: registry,
      );
    }();

    return null;
  }

  /// Retrieve a tile from the cache, if it exists
  Future<
      ({
        Uint8List bytes,
        CachedTileInformation tileInfo,
      })?> getTile(
    String uuid,
  ) async {
    if (!_registry.containsKey(uuid)) {
      unawaited(_removeTile(uuid));
      return null;
    }

    final tileFile = File(p.join(_cacheDirectory, uuid));

    try {
      return (bytes: await tileFile.readAsBytes(), tileInfo: _registry[uuid]!);
    } on FileSystemException {
      unawaited(_removeTile(uuid));
      return null;
    }
  }

  /// Add or update a tile in the cache
  ///
  /// [bytes] is required if the tile is not already cached.
  Future<void> putTile(
    String uuid,
    CachedTileInformation tileInfo, [
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
  Future<void> _removeTile(String uuid) async {
    final tileFile = File(p.join(_cacheDirectory, uuid));
    if (await tileFile.exists()) await tileFile.delete();

    if (_registry.remove(uuid) == null) return;
    _writeToPersistentRegistry(uuid, null);
  }
}
