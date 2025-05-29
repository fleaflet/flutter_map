import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/stub.dart'
    if (dart.library.io) 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/native.dart'
    if (dart.library.js_interop) 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/web/web.dart';

/// Simple built-in map caching using an I/O storage mechanism, for native
/// (non-web) platforms only
///
/// Stores tiles as files identified with keys, containing some metadata headers
/// followed by the tile bytes, alongside a file used to track the size of the
/// cache.
///
/// Usually uses HTTP headers to determine tile freshness, although
/// `overrideFreshAge` can override this.
///
/// This is enabled by default in flutter_map, when using the
/// [NetworkTileProvider] (or cancellable version).
///
/// For more information, see the online documentation.
abstract interface class BuiltInMapCachingProvider
    implements MapCachingProvider {
  /// if a singleton instance exists, return it, otherwise create a new
  /// singleton instance (and start asynchronously initialising it)
  ///
  /// If an instance already exists, the provided configuration will be ignored.
  ///
  /// See individual properties for more information about configuration.
  factory BuiltInMapCachingProvider.getOrCreateInstance({
    /// Path to the caching directory to use
    ///
    /// This must be accessible to the program.
    ///
    /// Defaults to a platform provided cache directory, which may be cleared by
    /// the OS at any time.
    String? cacheDirectory,

    /// Preferred maximum size (in bytes) of the cache
    ///
    /// This is applied when the internal caching mechanism is created (on the
    /// first tile load in the main memory space for the app). It is not an
    /// absolute limit.
    ///
    /// Defaults to 1 GB. Set to `null` to disable.
    int? maxCacheSize = 1_000_000_000,

    /// Override the duration of time a tile is considered fresh for
    ///
    /// Defaults to `null`: use duration calculated from each tile's HTTP
    /// headers.
    Duration? overrideFreshAge,

    /// Function to convert a tile URL to a key used in the cache
    ///
    /// This may be useful where parts of the URL are volatile or do not
    /// represent the tile image, for example, API keys contained with the query
    /// parameters.
    ///
    /// The resulting key should be unique to that tile URL. Keys must be usable
    /// as filenames on all intended platform filesystems.
    ///
    /// Defaults to generating a UUID from the entire URL string.
    ///
    /// The callback should not throw.
    String Function(String url)? cacheKeyGenerator,

    /// Prevent any tiles from being added or updated
    ///
    /// Does not disable the size limiter if the cache size is larger than
    /// `maxCacheSize`.
    ///
    /// Defaults to `false`.
    bool readOnly = false,
  }) {
    assert(
      maxCacheSize == null || maxCacheSize > 0,
      '`maxCacheSize` must be greater than 0 or disabled',
    );
    assert(
      overrideFreshAge == null || overrideFreshAge > Duration.zero,
      '`overrideFreshAge` must be greater than 0 or disabled',
    );
    return _instance ??= BuiltInMapCachingProviderImpl.createAndInitialise(
      cacheDirectory: cacheDirectory,
      maxCacheSize: maxCacheSize,
      overrideFreshAge: overrideFreshAge,
      cacheKeyGenerator: cacheKeyGenerator,
      readOnly: readOnly,
    );
  }

  static BuiltInMapCachingProviderImpl? _instance;
}
