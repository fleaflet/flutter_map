import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

@internal
class BuiltInMapCachingProviderImpl
    with DisabledMapCachingProvider
    implements BuiltInMapCachingProvider {
  final String? cacheDirectory;
  final int? maxCacheSize;
  final Duration? overrideFreshAge;
  final String Function(String url) cacheKeyGenerator;
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
  // False positive lint
  // ignore: prefer_void_to_null
  Future<Null> get isInitialised => SynchronousFuture(null);
}
