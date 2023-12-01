import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';

/// Dedicated [ImageProvider] to fetch tiles from the network
///
/// Supports falling back to a secondary URL, if the primary URL fetch fails.
/// Note that specifying a [fallbackUrl] will prevent this image provider from
/// being cached.
@immutable
class FlutterMapNetworkImageProvider
    extends ImageProvider<FlutterMapNetworkImageProvider> {
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
  final BaseClient httpClient;

  /// Whether to ignore exceptions and errors that occur whilst fetching tiles
  /// over the network, and just return a transparent tile
  final bool silenceExceptions;

  /// Function invoked when the image starts loading (not from cache)
  ///
  /// Used with [finishedLoadingBytes] to safely dispose of the [httpClient] only
  /// after all tiles have loaded.
  final void Function()? startedLoading;

  /// Function invoked when the image completes loading bytes from the network
  ///
  /// Used with [finishedLoadingBytes] to safely dispose of the [httpClient] only
  /// after all tiles have loaded.
  final void Function()? finishedLoadingBytes;

  /// Create a dedicated [ImageProvider] to fetch tiles from the network
  ///
  /// Supports falling back to a secondary URL, if the primary URL fetch fails.
  /// Note that specifying a [fallbackUrl] will prevent this image provider from
  /// being cached.
  const FlutterMapNetworkImageProvider({
    required this.url,
    required this.fallbackUrl,
    required this.headers,
    required this.httpClient,
    this.silenceExceptions = false,
    this.startedLoading,
    this.finishedLoadingBytes,
  });

  @override
  ImageStreamCompleter loadImage(
    FlutterMapNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    startedLoading?.call();

    return MultiFrameImageStreamCompleter(
      codec: _loadBytes(key, decode)
          .whenComplete(finishedLoadingBytes ?? () {})
          .then(ImmutableBuffer.fromUint8List)
          .then(decode),
      scale: 1,
      debugLabel: url,
      informationCollector: () => [
        DiagnosticsProperty('URL', url),
        DiagnosticsProperty('Fallback URL', fallbackUrl),
        DiagnosticsProperty('Current provider', key),
      ],
    );
  }

  Future<Uint8List> _loadBytes(
    FlutterMapNetworkImageProvider key,
    ImageDecoderCallback decode, {
    bool useFallback = false,
  }) =>
      httpClient
          .readBytes(
        Uri.parse(useFallback ? fallbackUrl ?? '' : url),
        headers: headers,
      )
          .catchError((Object err, StackTrace stack) {
        scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
        if (useFallback || fallbackUrl == null) {
          if (silenceExceptions) return TileProvider.transparentImage;
          return Future<Uint8List>.error(err, stack);
        }
        return _loadBytes(key, decode, useFallback: true);
      });

  @override
  SynchronousFuture<FlutterMapNetworkImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) =>
      SynchronousFuture(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlutterMapNetworkImageProvider &&
          fallbackUrl == null &&
          url == other.url);

  @override
  int get hashCode =>
      Object.hashAll([url, if (fallbackUrl != null) fallbackUrl]);
}
