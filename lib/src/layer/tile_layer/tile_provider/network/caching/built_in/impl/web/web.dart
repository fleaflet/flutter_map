import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

@internal
class BuiltInMapCachingProviderImpl implements BuiltInMapCachingProvider {
  final String? cacheDirectory;
  final int? maxCacheSize;
  final Duration? overrideFreshAge;
  final String Function(String url) cacheKeyGenerator;

  @internal
  const BuiltInMapCachingProviderImpl.createAndInitialise({
    required this.cacheDirectory,
    required this.maxCacheSize,
    required this.overrideFreshAge,
    required this.cacheKeyGenerator,
  });

  @override
  bool get isSupported => false;

  @override
  Future<void> get isInitialised => SynchronousFuture(null);

  @override
  Future<({Uint8List bytes, CachedMapTileMetadata tileInfo})?> getTile(
    String url,
  ) =>
      throw UnsupportedError('Built-in map caching is not supported on web');

  @override
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata tileInfo,
    Uint8List? bytes,
  }) =>
      throw UnsupportedError('Built-in map caching is not supported on web');
}
