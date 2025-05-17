import 'dart:async';
import 'dart:io'
    show HttpHeaders, HttpDate, HttpException, HttpStatus; // this is web safe!
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';

part 'tile_loader_simple.dart';
part 'tile_loader_with_caching.dart';

/// Dedicated [ImageProvider] to fetch tiles from the network
///
/// Supports falling back to a secondary URL, if the primary URL fetch fails.
/// Note that specifying a [fallbackUrl] will prevent this image provider from
/// being cached.
@immutable
class NetworkTileImageProvider extends ImageProvider<NetworkTileImageProvider> {
  /// The URL to fetch the tile from (GET request)
  final String url;

  /// The URL to fetch the tile from (GET request), in the event the original
  /// [url] request fails
  ///
  /// If this is non-null, [operator==] will always return `false` (except if
  /// the two objects are [identical]). Therefore, if this is non-null, this
  /// image provider will not be cached in memory.
  final String? fallbackUrl;

  /// The headers to include with the tile fetch request
  ///
  /// Not included in [operator==].
  final Map<String, String> headers;

  /// The HTTP client to use to make network requests
  ///
  /// Not included in [operator==].
  final Client httpClient;

  /// Whether to ignore exceptions and errors that occur whilst fetching tiles
  /// over the network, and just return a transparent tile
  ///
  /// Not included in [operator==].
  final bool silenceExceptions;

  /// Caching provider used to get cached tiles
  ///
  /// See online documentation for more information about built-in caching.
  ///
  /// Defaults to [BuiltInMapCachingProvider]. Set to
  /// [DisabledMapCachingProvider] to disable.
  ///
  /// Not included in [operator==].
  final MapCachingProvider? cachingProvider;

  /// Function invoked when the image starts loading (not from cache)
  ///
  /// Used with [finishedLoadingBytes] to safely dispose of the [httpClient] only
  /// after all tiles have loaded.
  final void Function() startedLoading;

  /// Function invoked when the image completes loading bytes from the network
  ///
  /// Used with [finishedLoadingBytes] to safely dispose of the [httpClient] only
  /// after all tiles have loaded.
  final void Function() finishedLoadingBytes;

  /// Create a dedicated [ImageProvider] to fetch tiles from the network
  ///
  /// Supports falling back to a secondary URL, if the primary URL fetch fails.
  /// Note that specifying a [fallbackUrl] will prevent this image provider from
  /// being cached.
  const NetworkTileImageProvider({
    required this.url,
    required this.fallbackUrl,
    required this.headers,
    required this.httpClient,
    required this.silenceExceptions,
    required this.cachingProvider,
    required this.startedLoading,
    required this.finishedLoadingBytes,
  });

  @override
  ImageStreamCompleter loadImage(
    NetworkTileImageProvider key,
    ImageDecoderCallback decode,
  ) =>
      MultiFrameImageStreamCompleter(
        codec: _load(key, decode),
        scale: 1,
        debugLabel: url,
        informationCollector: () => [
          DiagnosticsProperty('URL', url),
          DiagnosticsProperty('Fallback URL', fallbackUrl),
          DiagnosticsProperty('Current provider', key),
        ],
      );

  Future<Codec> _load(
    NetworkTileImageProvider key,
    ImageDecoderCallback decode, {
    bool useFallback = false,
  }) =>
      _loadTileImageWithCaching(key, decode, useFallback: useFallback);

  @override
  SynchronousFuture<NetworkTileImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) =>
      SynchronousFuture(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NetworkTileImageProvider &&
          fallbackUrl == null &&
          url == other.url);

  @override
  int get hashCode =>
      Object.hashAll([url, if (fallbackUrl != null) fallbackUrl]);
}
