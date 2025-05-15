import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';

/// Provides tile caching facilities based on HTTP headers (see
/// [CachedMapTileMetadata]) to [TileProvider]s
///
/// Some caching plugins may choose instead to provide a dedicated
/// [TileProvider], in which case the flutter_map-provided caching facilities
/// are irrelevant.
abstract interface class MapCachingProvider {
  /// Whether this caching provider is "currently supported"
  ///
  /// This can mean multiple things depending on the implementation's choice.
  /// However, it is used the same in the [NetworkTileProvider] implementaiton.
  ///
  /// In some implementations, such as [BuiltInMapCachingProvider], this is set
  /// constantly to indicate whether the implementation supports the current
  /// platform. [getTile] and other implementation specific methods are used
  /// to automatically wait for the internal initialisation to be complete
  /// before returning a tile. In this case, the provider delays the loading of
  /// tiles until initialisation is complete.
  ///
  /// In other implementations, [isSupported] may be set to indicate the
  /// internal initialisation status. In this case, the provider does not delay
  /// loading of tiles until initialisation is complete, and instead
  /// automatically switches to using cached tiles once ready.
  bool get isSupported;

  /// Retrieve a tile from the cache, if it exists
  Future<({Uint8List bytes, CachedMapTileMetadata tileInfo})?> getTile(
    String url,
  );

  /// Add or update a tile in the cache
  ///
  /// [bytes] is required if the tile is not already cached.
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata tileInfo,
    Uint8List? bytes,
  });
}
