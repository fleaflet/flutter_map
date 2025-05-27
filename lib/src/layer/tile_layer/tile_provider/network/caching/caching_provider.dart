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
  /// This may throw. Tile providers should anticipate this and fallback to a
  /// non-caching alternative.
  Future<({Uint8List bytes, CachedMapTileMetadata metadata})?> getTile(
    String url,
  );

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
