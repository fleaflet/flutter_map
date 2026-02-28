import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';

/// Caching provider which disables built-in caching
mixin class DisabledMapCachingProvider<IM extends Object?>
    implements
        MapCachingProvider,
        PutTileCapability,
        PutTileAndMetadataCapability<IM> {
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
    Uint8List? bytes,
  }) =>
      throw UnsupportedError('Must not be called if `isSupported` is `false`');

  @override
  Never putTileWithMetadata({
    required String url,
    required IM metadata,
    Uint8List? bytes,
  }) =>
      throw UnsupportedError('Must not be called if `isSupported` is `false`');
}
