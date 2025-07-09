import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';

/// Provides tile caching facilities to [TileProvider]s
///
/// Some caching plugins may choose instead to provide a dedicated
/// [TileProvider], in which case the flutter_map-provided caching facilities
/// are irrelevant.
///
/// The [CachedMapTileMetadata] object is used to store metadata alongside
/// cached tiles. Its intended purpose is primarily for caching based on HTTP
/// headers - however, this is not a requirement.
abstract interface class MapCachingProvider {
  /// Whether this caching provider is "currently supported": whether the
  /// tile provider should attempt to use it, or fallback to a non-caching
  /// alternative
  ///
  /// Tile providers must not call [getTile] or [putTile] if this is `false`.
  /// [getTile] and [putTile] should gracefully throw if this is `false`.
  /// This should not throw.
  ///
  /// If this is always `false`, consider mixing in or using
  /// [DisabledMapCachingProvider] directly.
  bool get isSupported;

  /// Retrieve a tile from the cache, if it exists
  ///
  /// Returns `null` if the tile was not present in the cache.
  ///
  /// If the tile was present, but could not be correctly read (for example, due
  /// to an unexpected corruption), this may throw [CachedMapTileReadFailure].
  /// Additionally, any returned tile image `bytes` are not guaranteed to form a
  /// valid image - attempting to decode the bytes may also throw.
  /// Tile providers should anticipate these exceptions and fallback to a
  /// non-caching alternative, wherever possible repairing or replacing the tile
  /// with a fresh & valid one.
  Future<CachedMapTile?> getTile(String url);

  /// Add or update a tile in the cache
  ///
  /// [bytes] is required if the tile is not already cached. The behaviour is
  /// implementation specific if bytes are not supplied when required.
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata metadata,
    Uint8List? bytes,
  });
}

/// A tile's bytes and metadata returned from [MapCachingProvider.getTile]
typedef CachedMapTile = ({Uint8List bytes, CachedMapTileMetadata metadata});
