import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils/test_tile_image.dart';

void main() {
  Future<TileImage> loadFailingTile({ImageProvider? errorImage}) {
    final loaded = Completer<void>();
    final tileImage = TileImage(
      coordinates: const TileCoordinates(0, 0, 0),
      vsync: const _TestTickerProvider(),
      imageProvider: _FailingImageProvider(),
      onLoadComplete: (_) => loaded.complete(),
      onLoadError: (_, __, ___) {},
      tileDisplay: const TileDisplay.instantaneous(),
      cancelLoading: Completer(),
      errorImage: errorImage,
    )..load();
    return loaded.future.then((_) => tileImage);
  }

  test('a failed tile with no error image is not ready to display', () async {
    final tileImage = await loadFailingTile();

    expect(tileImage.loadError, isTrue);
    expect(tileImage.readyToDisplay, isFalse);
  });

  test('a failed tile with an error image is ready to display', () async {
    final tileImage = await loadFailingTile(errorImage: testWhiteTileImage);

    expect(tileImage.loadError, isTrue);
    expect(tileImage.readyToDisplay, isTrue);
  });
}

class _FailingImageProvider extends ImageProvider<_FailingImageProvider> {
  @override
  Future<_FailingImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _FailingImageProvider key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(Future.error(Exception('tile unavailable')));
}

class _TestTickerProvider implements TickerProvider {
  const _TestTickerProvider();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker((_) {});
}
