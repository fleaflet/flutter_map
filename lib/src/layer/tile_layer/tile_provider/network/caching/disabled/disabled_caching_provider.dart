import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';

/// Map caching provider which disables caching
class DisabledMapCachingProvider implements MapCachingProvider {
  /// Disable map caching through the [NetworkTileProvider.cachingProvider]
  const DisabledMapCachingProvider();

  @override
  bool get isSupported => false;

  @override
  Never getTile(String url) => throw StateError('Caching should be disabled');

  @override
  Never putTile({
    required String url,
    required CachedMapTileMetadata tileInfo,
    Uint8List? bytes,
  }) =>
      throw StateError('Caching should be disabled');
}
