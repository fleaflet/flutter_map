import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Similar to [MemoryImage], but requires a [key] to identify and cache the
/// image, and supports lazily getting the image bytes with chunk support
class KeyedDelegatedImage extends ImageProvider<KeyedDelegatedImage> {
  /// Similar to [MemoryImage], but requires a [key] to identify and cache the
  /// image, and supports lazily getting the image bytes with chunk support
  const KeyedDelegatedImage({
    required this.key,
    required this.delegate,
    this.scale = 1.0,
  });

  /// Identifier for this image.
  ///
  /// This is used (alongside [scale]) to identify this image in the image
  /// cache. Therefore, two requirements must be met:
  ///
  ///  * The same key must not be used for two different images
  ///  * The same image should always use the same key
  final Object key;

  /// Callback which returns the codec to use as an image.
  ///
  /// Using the provided `chunkEvents` stream is optional, but may be used to
  /// report image loading progress.
  ///
  /// The `decode` callback provides the logic to obtain the codec for the
  /// image. It works on image bytes encoded in any of the following supported
  /// image formats:
  /// {@macro dart.ui.imageFormats}
  ///
  /// See also:
  ///
  ///  * [PaintingBinding.instantiateImageCodecWithSize]
  final Future<Codec> Function(
    KeyedDelegatedImage key, {
    required StreamSink<ImageChunkEvent> chunkEvents,
    required ImageDecoderCallback decode,
  }) delegate;

  /// The scale to place in the [ImageInfo] object of the image.
  ///
  /// See also:
  ///
  ///  * [ImageInfo.scale], which gives more information on how this scale is
  ///    applied.
  final double scale;

  @override
  Future<KeyedDelegatedImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<KeyedDelegatedImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    KeyedDelegatedImage key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: delegate(key, chunkEvents: chunkEvents.sink, decode: decode)
        ..whenComplete(chunkEvents.close),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: 'KeyedDelegatedImage($key)',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyedDelegatedImage &&
          other.key == key &&
          other.scale == scale);

  @override
  int get hashCode => Object.hash(key, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'KeyedDelegatedImage')}(key: $key, scale: ${scale.toStringAsFixed(1)})';
}
