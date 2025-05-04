import 'dart:async';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/base_tile_provider.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/independent/image_provider.dart';
import 'package:meta/meta.dart';

@internal
Future<Codec> loadTileImage(
  NetworkTileImageProvider key,
  ImageDecoderCallback decode, {
  bool useFallback = false,
}) =>
    _webLoadTileImage(key, decode, useFallback: useFallback);

@internal
Future<Codec> simpleLoadTileImage(
  NetworkTileImageProvider key,
  ImageDecoderCallback decode, {
  bool useFallback = false,
}) =>
    _webLoadTileImage(key, decode, useFallback: useFallback);

Future<Codec> _webLoadTileImage(
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
    return _webLoadTileImage(key, decode, useFallback: true);
  });
}
