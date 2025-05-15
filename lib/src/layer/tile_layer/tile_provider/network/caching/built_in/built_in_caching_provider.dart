import 'package:flutter_map/flutter_map.dart';
// TODO: On Dart 3.8 min, update to remove `@internal`s, switch to privates and conditional parts
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/stub.dart'
    if (dart.library.io) 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/native.dart'
    if (dart.library.js_interop) 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/web/web.dart';

import 'package:uuid/data.dart';
import 'package:uuid/rng.dart';
import 'package:uuid/uuid.dart';

/// Simple built-in map caching respecting HTTP headers using the filesystem
/// and a JSON registry, on native (non-web) platforms only
///
/// This is enabled by default. For more information, see the online
/// documentation.
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
    /// This may cause some slight delay to the loading of the first tiles,
    /// especially if the size is large and the cache does exceed the size. If
    /// the visible delay becomes too large, disable this and manage the cache
    /// size manually if necessary.
    ///
    /// Defaults to 1GB. Set to `null` to disable.
    int? maxCacheSize = 1000000000,

    /// Override the duration of time a tile is considered fresh for
    ///
    /// Defaults to `null`: use duration calculated from each tile's HTTP headers.
    Duration? overrideFreshAge,

    /// Function to convert a tile URL to a key used in the cache
    ///
    /// This may be useful where parts of the URL are volatile or do not represent
    /// the tile image, for example, API keys contained with the query parameters.
    ///
    /// The resulting key should be unique to that tile URL.
    ///
    /// Defaults to generating a UUID from the entire URL string.
    String Function(String url)? cacheKeyGenerator,
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
      cacheKeyGenerator:
          cacheKeyGenerator ?? (url) => _uuid.v5(Namespace.url.value, url),
    );
  }

  static BuiltInMapCachingProviderImpl? _instance;

  static final _uuid = Uuid(goptions: GlobalOptions(MathRNG()));

  /// Completes when the current instance has initialised and is ready to load
  /// and write tiles
  ///
  /// See online documentation to see how to use this to preload caching to
  /// remove the initial delay before loading tiles.
  ///
  /// May complete with an error if initialisation failed.
  ///
  /// On the web, this will always complete successfully immediately in the same
  /// event loop. Caching will not be available.
  Future<void> get isInitialised;
}
