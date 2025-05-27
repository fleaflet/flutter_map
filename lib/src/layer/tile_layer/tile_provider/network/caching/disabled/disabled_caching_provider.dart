import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';

/// Caching provider which disables built-in caching
mixin class DisabledMapCachingProvider implements MapCachingProvider {
  /// Disable built-in map caching
  const DisabledMapCachingProvider();

  @override
  bool get isSupported => false;

  @override
  Never getTile(String url) =>
      throw UnsupportedError('Must not be called if `isSupported` is `false`');

  @override
  Never putTile({
    required String url,
    required CachedMapTileMetadata metadata,
    Uint8List? bytes,
  }) =>
      throw UnsupportedError('Must not be called if `isSupported` is `false`');
}
