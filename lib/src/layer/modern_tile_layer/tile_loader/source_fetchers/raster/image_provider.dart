import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Similar to [MemoryImage], but requires a [key] to identify and cache the
/// image, and supports lazily getting the image bytes with chunk support
class KeyedGeneratedBytesImage extends ImageProvider<KeyedGeneratedBytesImage> {
  /// Similar to [MemoryImage], but requires a [key] to identify and cache the
  /// image, and supports lazily getting the image bytes with chunk support
  const KeyedGeneratedBytesImage({
    required this.key,
    required this.bytesGetter,
    this.scale = 1.0,
  });

  /// Identifier for this image
  ///
  /// This is used (alongside [scale]) to identify this image in the image
  /// cache. Therefore, two requirements must be met:
  ///
  ///  * The same key must not be used for two different images
  ///  * The same image should always use the same key
  final Object key;

  /// Callback which returns the bytes to decode into an image.
  ///
  /// Using the provided `chunkEvents` stream is optional, but may be used to
  /// report image loading progress.
  ///
  /// The bytes represent encoded image bytes and can be encoded in any of the
  /// following supported image formats: {@macro dart.ui.imageFormats}
  ///
  /// See also:
  ///
  ///  * [PaintingBinding.instantiateImageCodecWithSize]
  final FutureOr<Uint8List> Function(StreamSink<ImageChunkEvent> chunkEvents)
      bytesGetter;

  /// The scale to place in the [ImageInfo] object of the image.
  ///
  /// See also:
  ///
  ///  * [ImageInfo.scale], which gives more information on how this scale is
  ///    applied.
  final double scale;

  @override
  Future<KeyedGeneratedBytesImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<KeyedGeneratedBytesImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    KeyedGeneratedBytesImage key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents: chunkEvents.sink, decode: decode)
        ..then(
          (_) => unawaited(chunkEvents.close()),
          onError: (_) => unawaited(chunkEvents.close()),
        ),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: 'KeyedGeneratedBytesImage($key)',
    );
  }

  Future<Codec> _loadAsync(
    KeyedGeneratedBytesImage key, {
    required StreamSink<ImageChunkEvent> chunkEvents,
    required ImageDecoderCallback decode,
  }) async =>
      await decode(
        await ImmutableBuffer.fromUint8List(await bytesGetter(chunkEvents)),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyedGeneratedBytesImage &&
          other.key == key &&
          other.scale == scale);

  @override
  int get hashCode => Object.hash(key, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'KeyedGeneratedBytesImage')}(key: $key, scale: ${scale.toStringAsFixed(1)})';
}
