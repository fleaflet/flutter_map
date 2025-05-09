import 'package:meta/meta.dart';

/// Configuration of the built-in caching
@immutable
class MapCachingOptions {
  /// Path to the caching directory to use
  ///
  /// This must be accessible to the program.
  ///
  /// Defaults to a platform provided cache directory, which may be cleared by
  /// the OS at any time.
  final String? cacheDirectory;

  /// Preferred maximum size (in bytes) of the cache
  ///
  /// This is applied when the internal caching mechanism is created (on the
  /// first tile load in the main memory space for the app). It is not an
  /// absolute limit.
  ///
  /// This may cause some slight delay to the loading of the first tiles,
  /// especially if the size is large and the cache does exceed the size. If
  /// the visible delay becomes too large, disable this and manage the cache
  /// size manually if necessary.
  ///
  /// Defaults to 1GB. Set to `null` to disable.
  final int? maxCacheSize;

  /// Override the duration of time a tile is considered fresh for
  ///
  /// Defaults to `null`: use duration calculated from each tile's HTTP headers.
  final Duration? overrideFreshAge;

  /// Function to convert a tile URL to a key used in the cache
  ///
  /// This may be useful where parts of the URL are volatile or do not represent
  /// the tile image, for example, API keys contained with the query parameters.
  ///
  /// The resulting key should be unique to that tile URL.
  ///
  /// Defaults to generating a UUID from the entire URL string.
  final String Function(String url)? cacheKeyGenerator;

  /// Create a configuration for caching
  const MapCachingOptions({
    this.cacheDirectory,
    this.maxCacheSize = 1000000000,
    this.overrideFreshAge,
    this.cacheKeyGenerator,
  })  : assert(
          maxCacheSize == null || maxCacheSize > 0,
          '`maxCacheSize` must be greater than 0 or disabled',
        ),
        assert(
          overrideFreshAge == null || overrideFreshAge > Duration.zero,
          '`overrideFreshAge` must be greater than 0 or disabled',
        );

  @override
  int get hashCode => Object.hash(
        cacheDirectory,
        maxCacheSize,
        overrideFreshAge,
        cacheKeyGenerator,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MapCachingOptions &&
          cacheDirectory == other.cacheDirectory &&
          maxCacheSize == other.maxCacheSize &&
          overrideFreshAge == other.overrideFreshAge &&
          cacheKeyGenerator == other.cacheKeyGenerator);
}
