import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

class CancellableNetworkTileProvider extends TileProvider {
  CancellableNetworkTileProvider({
    super.headers,
    BaseClient? httpClient,
  }) : httpClient = httpClient ?? RetryClient(Client());

  final BaseClient httpClient;

  @override
  bool get supportsCancelLoading => true;

  @override
  ImageProvider getImageWithCancelLoadingSupport(
    TileCoordinates coordinates,
    TileLayer options,
    Future<void> cancelLoading,
  ) =>
      CancellableNetworkImageProvider(
        url: getTileUrl(coordinates, options),
        fallbackUrl: getTileFallbackUrl(coordinates, options),
        headers: headers,
        httpClient: httpClient,
        cancelLoading: cancelLoading,
      );
}

class CancellableNetworkImageProvider
    extends ImageProvider<CancellableNetworkImageProvider> {
  final String url;
  final String? fallbackUrl;
  final BaseClient httpClient;
  final Map<String, String> headers;
  final Future<void> cancelLoading;

  const CancellableNetworkImageProvider({
    required this.url,
    required this.fallbackUrl,
    required this.headers,
    required this.httpClient,
    required this.cancelLoading,
  });

  @override
  ImageStreamCompleter loadImage(
    CancellableNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();

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
  Future<CancellableNetworkImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) =>
      SynchronousFuture<CancellableNetworkImageProvider>(this);

  Future<Codec> _loadAsync(
    CancellableNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode, {
    bool useFallback = false,
  }) async {
    final cancelToken = CancelToken();
    cancelLoading.then((_) => cancelToken.cancel());

    final Uint8List bytes;
    try {
      final dio = Dio();
      final response = await dio.get<Uint8List>(
        useFallback ? fallbackUrl ?? '' : url,
        cancelToken: cancelToken,
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
        ),
      );
      bytes = response.data!;
    } on DioException catch (err) {
      if (CancelToken.isCancel(err)) {
        return decode(
          await ImmutableBuffer.fromUint8List(TileProvider.transparentImage),
        );
      }
      if (useFallback || fallbackUrl == null) rethrow;
      return _loadAsync(key, chunkEvents, decode, useFallback: true);
    } catch (_) {
      if (useFallback || fallbackUrl == null) rethrow;
      return _loadAsync(key, chunkEvents, decode, useFallback: true);
    }

    return decode(await ImmutableBuffer.fromUint8List(bytes));
  }
}
