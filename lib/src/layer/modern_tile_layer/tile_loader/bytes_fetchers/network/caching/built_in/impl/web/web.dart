import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

@internal
class BuiltInMapCachingProviderImpl
    with DisabledMapCachingProvider<HttpControlledCachedTileMetadata>
    implements BuiltInMapCachingProvider {
  final String? cacheDirectory;
  final int? maxCacheSize;
  final String Function(String url) tileKeyGenerator;
  final Duration? overrideFreshAge;
  final bool readOnly;

  final void Function() resetSingleton;

  @internal
  const BuiltInMapCachingProviderImpl.create({
    required this.cacheDirectory,
    required this.maxCacheSize,
    required this.overrideFreshAge,
    required this.tileKeyGenerator,
    required this.readOnly,
    required this.resetSingleton,
  });

  @override
  Future<void> destroy({bool deleteCache = false}) => Future.value();
}
