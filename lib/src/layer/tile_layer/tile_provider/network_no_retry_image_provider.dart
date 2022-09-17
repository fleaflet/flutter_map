import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class FMNetworkNoRetryImageProvider
    extends ImageProvider<FMNetworkNoRetryImageProvider> {
  /// A valid URL, which is the location of the image to be fetched
  final String url;

  /// The fallback URL from which the image will be fetched.
  final String? fallbackUrl;

  /// The client which will be used to fetch the image
  final HttpClient httpClient;

  /// Custom headers to add to the image fetch request
  final Map<String, String> headers;

  FMNetworkNoRetryImageProvider(
    this.url, {
    required this.fallbackUrl,
    HttpClient? httpClient,
    this.headers = const {},
  }) : httpClient = httpClient ?? HttpClient()
          ..userAgent = null;

  @override
  ImageStreamCompleter loadBuffer(
    FMNetworkNoRetryImageProvider key,
    DecoderBufferCallback decode,
  ) {
    //ignore: close_sinks
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key: key, decode: decode, chunkEvents: chunkEvents),
      chunkEvents: chunkEvents.stream,
      scale: 1,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<FMNetworkNoRetryImageProvider>('Image key', key),
      ],
    );
  }

  @override
  Future<FMNetworkNoRetryImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<FMNetworkNoRetryImageProvider>(this);
  }

  Future<Codec> _loadAsync({
    required FMNetworkNoRetryImageProvider key,
    required DecoderBufferCallback decode,
    required StreamController<ImageChunkEvent> chunkEvents,
    bool useFallback = false,
  }) async {
    try {
      assert(key == this);
      assert(useFallback == false || fallbackUrl != null);

      final Uri resolved =
          Uri.base.resolve(useFallback ? key.fallbackUrl! : key.url);

      final HttpClientRequest request = await httpClient.getUrl(resolved);

      headers.forEach((String name, String value) {
        request.headers.add(name, value);
      });

      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<List<int>>(<int>[]);
        throw NetworkImageLoadException(
            statusCode: response.statusCode, uri: resolved);
      }

      final Uint8List bytes = await consolidateHttpClientResponseBytes(
        response,
        onBytesReceived: (int cumulative, int? total) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: cumulative,
            expectedTotalBytes: total,
          ));
        },
      );
      if (bytes.lengthInBytes == 0) {
        throw Exception('NetworkImage is an empty file: $resolved');
      }

      return decode(await ImmutableBuffer.fromUint8List(bytes));
    } catch (e) {
      if (!useFallback && fallbackUrl != null) {
        return _loadAsync(
          key: key,
          decode: decode,
          chunkEvents: chunkEvents,
          useFallback: true,
        );
      }

      scheduleMicrotask(() {
        _ambiguate(_ambiguate(PaintingBinding.instance)?.imageCache)
            ?.evict(key);
      });
      chunkEvents.close();
      rethrow;
    }
  }

  T? _ambiguate<T>(T? value) => value;
}
