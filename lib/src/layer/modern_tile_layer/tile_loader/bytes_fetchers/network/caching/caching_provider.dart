import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/bytes_fetchers/network/fetcher/network.dart';
import 'package:meta/meta.dart';

/// Provides tile caching facilities.
///
/// A cached tile is considered to be at least bytes representing the tile
/// resource, usually paired with metadata about the tile resource.
///
/// Implementations usually mix-in/implement at least one of [PutTileCapability]
/// and/or [PutTileAndMetadataCapability], to allow tiles to be added to the
/// cache by compatible external consumers.
///
/// To be supported by the [NetworkBytesFetcher], at least one of the following
/// must be mixed-in/implemented:
///  * [PutTileCapability]
///  * [PutTileAndMetadataCapability] with a metadata type parameter of
///    [HttpControlledCachedTileMetadata]
abstract interface class MapCachingProvider {
  /// Whether this caching provider is "currently supported": whether the
  /// tile provider should attempt to use it, or fallback to a non-caching
  /// alternative.
  ///
  /// Tile providers must not use any other members if this is `false`. Where
  /// possible, other methods should gracefully throw if this is `false`. This
  /// should not throw.
  ///
  /// If this is always `false`, consider mixing in or using
  /// [DisabledMapCachingProvider] directly.
  bool get isSupported;

  /// Retrieve a tile from the cache, if it exists.
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
  ///
  /// If this method throws an error/exception other than
  /// [CachedMapTileReadFailure], consumers should rethrow the error.
  ///
  /// If the tile is available, the metadata at least gives an indication as to
  /// whether the tile is 'stale'. The metadata may also be a more informative
  /// subclass, such as [HttpControlledCachedTileMetadata].
  Future<CachedMapTile?> getTile(String url);
}

/// Allows a [MapCachingProvider] to have tiles added externally, without
/// metadata.
abstract interface class PutTileCapability implements MapCachingProvider {
  /// Add or update a tile in the cache.
  ///
  /// [bytes] is required if the tile is not already cached. The behaviour is
  /// implementation specific if bytes are not supplied when required.
  void putTile({
    required String url,
    Uint8List? bytes,
  });
}

/// Allows a [MapCachingProvider] to have tiles added externally, with
/// metadata.
abstract interface class PutTileAndMetadataCapability<IM extends Object?>
    implements MapCachingProvider {
  /// Add or update a tile & its metadata in the cache
  ///
  /// [bytes] is required if the tile is not already cached. The behaviour is
  /// implementation specific if bytes are not supplied when required.
  void putTileWithMetadata({
    required String url,
    required IM metadata,
    Uint8List? bytes,
  });
}

/// A tile's bytes and metadata returned from [MapCachingProvider.getTile]
///
/// Depending on the caching provider, `metadata` may be a more specific subtype.
@optionalTypeArgs
typedef CachedMapTile<OM extends CachedTileMetadata> = ({
  Uint8List bytes,
  OM metadata,
});
