import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart';

/// Dedicated [ImageProvider] to fetch tiles from the network
class FlutterMapNetworkImageProvider
    extends ImageProvider<FlutterMapNetworkImageProvider> {
  /// The URL to fetch the tile from (GET request)
  final String url;

  /// The URL to fetch the tile from (GET request), in the event the original
  /// [url] request fails
  final String? fallbackUrl;

  /// The HTTP client to use to make network requests
  final BaseClient httpClient;

  /// The headers to include with the tile fetch request
  final Map<String, String> headers;

  /// Dedicated [ImageProvider] to fetch tiles from the network
  FlutterMapNetworkImageProvider({
    required this.url,
    required this.fallbackUrl,
    required this.headers,
    required this.httpClient,
  });

  @override
  ImageStreamCompleter loadImage(
    FlutterMapNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: 1,
      debugLabel: url,
      informationCollector: () => [
        DiagnosticsProperty('URL', url),
        DiagnosticsProperty('Fallback URL', fallbackUrl),
        DiagnosticsProperty('Current provider', key),
      ],
    );
  }

  @override
  Future<FlutterMapNetworkImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) =>
      SynchronousFuture<FlutterMapNetworkImageProvider>(this);

  Future<Codec> _loadAsync(
    FlutterMapNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode, {
    bool useFallback = false,
  }) async {
    final Uint8List bytes;
    try {
      bytes = await httpClient.readBytes(
        Uri.parse(useFallback ? fallbackUrl ?? '' : url),
        headers: headers,
      );
    } catch (_) {
      if (useFallback) rethrow;
      return _loadAsync(key, chunkEvents, decode, useFallback: true);
    }

    return decode(await ImmutableBuffer.fromUint8List(bytes));
  }
}
