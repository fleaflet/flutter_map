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
