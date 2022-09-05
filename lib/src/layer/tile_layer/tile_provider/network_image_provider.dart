import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

class FMNetworkImageProvider extends ImageProvider<FMNetworkImageProvider> {
  /// The URL from which the image will be fetched.
  final String url;

  /// The http RetryClient that is used for the requests
  final RetryClient retryClient;

  /// Custom headers to add to the image fetch request
  final Map<String, String> headers;

  FMNetworkImageProvider(
    this.url, {
    RetryClient? retryClient,
    this.headers = const {},
  }) : retryClient = retryClient ?? RetryClient(Client());

  @override
  ImageStreamCompleter loadBuffer(
      FMNetworkImageProvider key, DecoderBufferCallback decode) {
    return OneFrameImageStreamCompleter(_loadWithRetry(key, decode),
        informationCollector: () sync* {
      yield ErrorDescription('Image provider: $this');
      yield ErrorDescription('Image key: $key');
    });
  }

  @override
  Future<FMNetworkImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FMNetworkImageProvider>(this);
  }

  Future<ImageInfo> _loadWithRetry(
    FMNetworkImageProvider key,
    DecoderBufferCallback decode,
  ) async {
    assert(key == this);

    final uri = Uri.parse(url);
    final response = await retryClient.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw NetworkImageLoadException(
          statusCode: response.statusCode, uri: uri);
    }

    final codec =
        await decode(await ImmutableBuffer.fromUint8List(response.bodyBytes));
    final image = (await codec.getNextFrame()).image;

    return ImageInfo(image: image);
  }
}
