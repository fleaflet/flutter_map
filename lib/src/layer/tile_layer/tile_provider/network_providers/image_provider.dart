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

  // TODO: These [load] and [loadBuffer] method ensure support for Flutter 3.3
  // thru 3.10, hence the multiple deprecation ignorances. Once the methods &
  // types have been removed, they need to be replaced with [loadImage], and the
  // min SDK constraint will need to be bumped.

  @override
  ImageStreamCompleter load(
    FlutterMapNetworkImageProvider key,
    // ignore: deprecated_member_use
    DecoderCallback decode,
  ) {
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decodeDepreacted: decode),
      chunkEvents: chunkEvents.stream,
      scale: 1,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty('URL', url),
        DiagnosticsProperty('Fallback URL', fallbackUrl),
        DiagnosticsProperty('Current provider', key),
      ],
    );
  }

  @override
  ImageStreamCompleter loadBuffer(
    FlutterMapNetworkImageProvider key,
    // ignore: deprecated_member_use
    DecoderBufferCallback decode,
  ) {
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode: decode),
      chunkEvents: chunkEvents.stream,
      scale: 1,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty('URL', url),
        DiagnosticsProperty('Fallback URL', fallbackUrl),
        DiagnosticsProperty('Current provider', key),
      ],
    );
  }

  Future<Codec> _loadAsync(
    FlutterMapNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents, {
    // ignore: deprecated_member_use
    DecoderBufferCallback? decode,
    // ignore: deprecated_member_use
    DecoderCallback? decodeDepreacted,
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
      return _loadAsync(
        key,
        chunkEvents,
        decode: decode,
        decodeDepreacted: decodeDepreacted,
        useFallback: true,
      );
    }

    if (decode != null) {
      return decode(await ImmutableBuffer.fromUint8List(bytes));
    } else {
      return decodeDepreacted!(bytes);
    }
  }

  @override
  Future<FlutterMapNetworkImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) =>
      SynchronousFuture<FlutterMapNetworkImageProvider>(this);
}
