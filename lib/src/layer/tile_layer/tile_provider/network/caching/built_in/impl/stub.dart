import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// Internal stub implementation of [BuiltInMapCachingProvider]
///
/// Implemented based on platform in `native/` and `web/`. These must follow
/// the same structure as this stub.
@internal
class BuiltInMapCachingProviderImpl implements BuiltInMapCachingProvider {
  final String? cacheDirectory;
  final int? maxCacheSize;
  final Duration? overrideFreshAge;
  final String Function(String url)? cacheKeyGenerator;
  final bool readOnly;

  @internal
  const BuiltInMapCachingProviderImpl.createAndInitialise({
    required this.cacheDirectory,
    required this.maxCacheSize,
    required this.overrideFreshAge,
    required this.cacheKeyGenerator,
    required this.readOnly,
  });

  @override
  external bool get isSupported;

  @override
  external Future<({Uint8List bytes, CachedMapTileMetadata metadata})?> getTile(
    String url,
  );

  @override
  external Future<void> putTile({
    required String url,
    required CachedMapTileMetadata metadata,
    Uint8List? bytes,
  });
}
