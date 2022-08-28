import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

class FMNetworkImageProvider extends ImageProvider<FMNetworkImageProvider> {
  /// The URL from which the image will be fetched.
  final String url;

  /// The fallback URL from which the image will be fetched.
  final String? fallbackUrl;

  /// The http RetryClient that is used for the requests
  final RetryClient retryClient;

  /// Custom headers to add to the image fetch request
  final Map<String, String> headers;

  FMNetworkImageProvider(
    this.url, {
    required this.fallbackUrl,
    RetryClient? retryClient,
    this.headers = const {},
  }) : retryClient = retryClient ?? RetryClient(Client());

  @override
  ImageStreamCompleter load(
      FMNetworkImageProvider key, DecoderCallback decode) {
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
    DecoderCallback decode, [
    bool useFallback = false,
  ]) async {
    assert(key == this);
    assert(useFallback == false || fallbackUrl != null);

    try {
      final uri = Uri.parse(useFallback ? fallbackUrl! : url);
      final response = await retryClient.get(uri, headers: headers);

      if (response.statusCode != 200) {
        throw NetworkImageLoadException(
            statusCode: response.statusCode, uri: uri);
      }

      final codec = await decode(response.bodyBytes);
      final image = (await codec.getNextFrame()).image;

      return ImageInfo(image: image);
    } catch (e) {
      if (!useFallback && fallbackUrl != null) {
        return _loadWithRetry(key, decode, true);
      }
      rethrow;
    }
  }
}
