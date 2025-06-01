import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

@internal
class BuiltInMapCachingProviderImpl
    with DisabledMapCachingProvider
    implements BuiltInMapCachingProvider {
  final String? cacheDirectory;
  final int? maxCacheSize;
  final String Function(String url)? tileKeyGenerator;
  final Duration? overrideFreshAge;
  final bool readOnly;

  @internal
  const BuiltInMapCachingProviderImpl.createAndInitialise({
    required this.cacheDirectory,
    required this.maxCacheSize,
    required this.overrideFreshAge,
    required this.tileKeyGenerator,
    required this.readOnly,
  });
}
