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
  /// If an instance exists, return it, otherwise create a new instance
  ///
  /// The provided configuration will only be respected if an instance does not
  /// already exist.
  ///
  /// See individual properties for more information about configuration.
  factory BuiltInMapCachingProvider.getOrCreateInstance({
    /// Path to the directory to use to store cached tiles & other related files
    ///
    /// The provider actually uses the 'fm_cache' directory created as a child
    /// of the path specified here.
    ///
    /// The program must have rights/permissions to access the path.
    ///
    /// The path does not have to exist, it will be recursively created if
    /// missing.
    ///
    /// All files and directories within the path will be liable to deletion by
    /// the size reducer.
    ///
    /// Defaults to a platform provided cache directory, which may be cleared by
    /// the OS at any time.
    String? cacheDirectory,

    /// Maximum total size of cached tiles, in bytes
    ///
    /// This is applied only when the instance is created, by running the size
    /// reducer. This runs in the background (and so does not delay reads or
    /// writes). The cache size may exceed this limit while the program is
    /// running.
    ///
    /// Disabling the size limit may improve write performance.
    ///
    /// Defaults to 1 GB. Set to `null` to disable.
    int? maxCacheSize = 1_000_000_000,

    /// Function to convert a tile's URL to a key used to uniquely identify the
    /// tile
    ///
    /// Where parts of the URL are volatile or do not represent the tile's
    /// contents/image - for example, API keys contained with the query
    /// parameters - this should be modified to remove the volatile portions.
    ///
    /// Keys must be usable as filenames on all intended platform filesystems.
    /// The callback should not throw.
    ///
    /// Defaults to generating a UUID from the entire URL string.
    String Function(String url)? tileKeyGenerator,

    /// Override the duration of time a tile is considered fresh for
    ///
    /// Defaults to `null`: use duration calculated from each tile's HTTP
    /// headers.
    Duration? overrideFreshAge,

    /// Prevent any tiles from being added or updated
    ///
    /// Does not disable the size reducer if the cache size is larger than
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
      tileKeyGenerator: tileKeyGenerator,
      readOnly: readOnly,
    );
  }

  static BuiltInMapCachingProviderImpl? _instance;
}
