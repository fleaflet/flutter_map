import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TilePlaceholderImage {
  /// Creates an [ImageProvider] which resolves to an image which is a grid of
  /// [cellCount] transparent cells on both axis. The cells are transparent,
  /// divided by lines with the color [lineColor].
  ///
  /// The [size] determines the width and height of the generated image and it
  /// should match the tile size of the [TileLayer] in which this is used.
  ///
  /// The returned ImageProvider is intended to be stored in a static final
  /// variable and passed in to placeholderBuilder to reduce the memory
  /// footprint.
  static ImageProvider generate({
    int size = 256,
    Color lineColor = Colors.white,
    int cellCount = 8,
  }) {
    final sizeDouble = size.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(
        Offset.zero,
        Offset(sizeDouble, sizeDouble),
      ),
    );

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke;

    final cellOffsetSize = sizeDouble / cellCount;

    // Draw lines
    for (int i = 0; i <= cellCount; i++) {
      if (i % cellCount == 0) {
        paint.strokeWidth = 1;
      } else {
        paint.strokeWidth = 0.5;
      }
      final cellOffset = cellOffsetSize * i;
      // Horizontal line.
      canvas.drawLine(
        Offset(0, cellOffset),
        Offset(sizeDouble, cellOffset),
        paint,
      );
      // Vertical lines.
      canvas.drawLine(
        Offset(cellOffset, 0),
        Offset(cellOffset, sizeDouble),
        paint,
      );
    }

    final picture = recorder.endRecording();
    final img = picture.toImageSync(size, size);

    return _RawImageProvider(img);
  }
}

class _RawImageProvider extends ImageProvider<_RawImageProvider> {
  final ui.Image _image;

  _RawImageProvider(this._image);

  @override
  ImageStreamCompleter load(
    _RawImageProvider key,
    Future<ui.Codec> Function(
      Uint8List, {
      bool allowUpscaling,
      int? cacheHeight,
      int? cacheWidth,
    }) decode,
  ) =>
      // Clone is important here, otherwise the RawImageProvider might dispose
      // the original image.
      _RawImageStreamCompleter(_image.clone());

  @override
  Future<_RawImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_RawImageProvider>(this);
  }
}

class _RawImageStreamCompleter extends ImageStreamCompleter {
  _RawImageStreamCompleter(ui.Image image) {
    setImage(ImageInfo(image: image));
  }
}
