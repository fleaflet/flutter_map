part of 'image_provider.dart';

Future<Codec> _loadTileImageSimple(
  NetworkTileImageProvider key,
  ImageDecoderCallback decode, {
  bool useFallback = false,
}) {
  key.startedLoading();

  return key.httpClient
      .readBytes(
        Uri.parse(useFallback ? key.fallbackUrl ?? '' : key.url),
        headers: key.headers,
      )
      .whenComplete(key.finishedLoadingBytes)
      .then(ImmutableBuffer.fromUint8List)
      .then(decode)
      .onError<Exception>((err, stack) {
    scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
    if (useFallback || key.fallbackUrl == null) {
      if (!key.silenceExceptions) throw err;
      return ImmutableBuffer.fromUint8List(TileProvider.transparentImage)
          .then(decode);
    }
    return _loadTileImageSimple(key, decode, useFallback: true);
  });
}
