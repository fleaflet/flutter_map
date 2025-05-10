import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// {@template fm.mtcm}
/// Singleton class which manages simple built-in tile caching based HTTP
/// headers for native (I/O) platforms only
///
/// > [!IMPORTANT]
/// > Built-in tile caching is not a replacement for caching which can better
/// > guarantee resilience. It should not solely be used where not having
/// > cached tiles may lead to a dangerous situation - for example, offline
/// > mapping. This provides no guarantees as to the safety of cached tiles.
///
/// For more information, see the online documentation.
///
/// ---
///
/// Direct usage of this class is not usually necessary. It is visible so other
/// tile providers may make use of it.
///
/// ---
/// {@endtemplate}
@immutable
class MapTileCachingManager {
  const MapTileCachingManager._();

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
  }) =>
      throw UnsupportedError(
        '`MapTileCachingManager` is only implemented on I/O platforms',
      );

  /// Retrieve a tile from the cache, if it exists
  Future<
      ({
        Uint8List bytes,
        CachedMapTileMetadata tileInfo,
      })?> getTile(
    String uuid,
  ) =>
      throw UnsupportedError(
        '`MapTileCachingManager` is only implemented on I/O platforms',
      );

  /// Add or update a tile in the cache
  ///
  /// [bytes] is required if the tile is not already cached.
  Future<void> putTile(
    String uuid,
    CachedMapTileMetadata tileInfo, [
    Uint8List? bytes,
  ]) =>
      throw UnsupportedError(
        '`MapTileCachingManager` is only implemented on I/O platforms',
      );
}
