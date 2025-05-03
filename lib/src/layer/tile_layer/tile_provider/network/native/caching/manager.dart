import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
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
// TODO: Expose for other providers?
@immutable
class TileCachingManager {
  const TileCachingManager._({
    required String cacheDirectory,
    required void Function(String uuid, CachedTileInformation? tileInfo)
        persistentRegistryWriter,
    required Map<String, CachedTileInformation> registry,
  })  : _cacheDirectory = cacheDirectory,
        _writeToPersistentRegistry = persistentRegistryWriter,
        _registry = registry;

  /// Current instance of singleton
  ///
  /// Completer pattern used to obtain a lock - the first tile loaded takes
  /// slightly longer, as it has to create the first instance, so other tiles
  /// loaded simultaneously must wait instead of all attempting to create
  /// multiple singletons.
  static Completer<TileCachingManager>? _instance;

  final String _cacheDirectory;
  final void Function(String uuid, CachedTileInformation? tileInfo)
      _writeToPersistentRegistry;
  final Map<String, CachedTileInformation> _registry;

  /// Returns the current caching instance if one is already available,
  /// otherwise create and open a new instance
  ///
  /// If an instance is already being created, this will wait until that
  /// instance is available instead of creating a new one.
  ///
  /// Returns `null` if an instance does not exist and one could not be created.
  static Future<TileCachingManager?> getInstanceOrCreate({
    String? cacheDirectory,
  }) async {
    if (_instance != null) return await _instance!.future;

    _instance = Completer();

    final Directory resolvedCacheDirectory;
    try {
      resolvedCacheDirectory = Directory(
        p.join(
          cacheDirectory ??
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

    final persistentRegistryFilePath =
        p.join(resolvedCacheDirectory.absolute.path, 'manager.json');
    final persistentRegistryFile = File(persistentRegistryFilePath);

    final Map<String, CachedTileInformation> registry;
    try {
      if (await persistentRegistryFile.exists()) {
        final parsedCacheManager = await compute(
          _parsePersistentRegistryWorker,
          persistentRegistryFilePath,
        );
        if (parsedCacheManager == null) {
          await resolvedCacheDirectory.delete(recursive: true);
          await resolvedCacheDirectory.create(recursive: true);
          await persistentRegistryFile.create(recursive: true);
          registry = HashMap();
        } else {
          registry = parsedCacheManager;
        }

        //for (final MapEntry(key: uuid, value: tileInfo) in registry.entries) {}
      } else {
        await persistentRegistryFile.create(recursive: true);
        registry = HashMap();
      }
    } on FileSystemException {
      return null;
    }

    final receivePort = ReceivePort();
    try {
      await Isolate.spawn(
        _persistentRegistryWorkerIsolate,
        (
          port: receivePort.sendPort,
          persistentRegistryFilePath: persistentRegistryFilePath,
          initialRegistry: registry,
        ),
      );
    } catch (e) {
      return null;
    }
    final workerSendPort = await receivePort.first as SendPort;

    final instance = TileCachingManager._(
      cacheDirectory: resolvedCacheDirectory.absolute.path,
      persistentRegistryWriter: (uuid, tileInfo) =>
          workerSendPort.send((uuid: uuid, tileInfo: tileInfo)),
      registry: registry,
    );

    _instance!.complete(instance);
    return instance;
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
      unawaited(removeTile(uuid));
      return null;
    }

    final tileFile = File(p.join(_cacheDirectory, uuid));

    try {
      return (bytes: await tileFile.readAsBytes(), tileInfo: _registry[uuid]!);
    } on FileSystemException {
      unawaited(removeTile(uuid));
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

    final tileFile = File(p.join(_cacheDirectory, uuid));

    if (bytes == null && !await tileFile.exists()) {
      // more expensive condition last
      throw ArgumentError.notNull('bytes');
    }

    if (bytes != null) {
      try {
        await tileFile.create(recursive: true);
        await tileFile.writeAsBytes(bytes);
      } on FileSystemException {
        return;
      }
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
