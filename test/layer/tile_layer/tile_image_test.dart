import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

/// An [ImageProvider] whose image is delivered only when the test says so, and
/// whose key is itself, so that two [TileImage]s resolve to the SAME
/// [ImageStreamCompleter] (which is what [ImageCache] does for equal keys).
class _SharedManualImageProvider
    extends ImageProvider<_SharedManualImageProvider> {
  _SharedManualImageProvider(this.completer);

  final Completer<ImageInfo> completer;

  @override
  Future<_SharedManualImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) =>
      SynchronousFuture<_SharedManualImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    _SharedManualImageProvider key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(completer.future);
}

TileImage _tile({
  required int x,
  required ImageProvider provider,
  void Function(TileCoordinates)? onLoadComplete,
}) =>
    TileImage(
      vsync: const TestVSync(),
      coordinates: TileCoordinates(x, 0, 0),
      imageProvider: provider,
      onLoadComplete: onLoadComplete ?? (_) {},
      onLoadError: (_, __, ___) {},
      tileDisplay: const TileDisplay.instantaneous(),
      errorImage: null,
      cancelLoading: Completer<void>(),
    );

void main() {
  testWidgets(
    'disposes the image handed to a tile pruned during listener dispatch',
    (tester) async {
      // `runAsync`: decoding needs real async, which the fake clock inside
      // `testWidgets` never advances — awaiting it directly hangs the test.
      final image =
          (await tester.runAsync(() => createTestImage(width: 8, height: 8)))!;
      // Measured, not assumed: `createTestImage` may hand back an image that
      // already has more than one handle open.
      final baseline = image.debugGetOpenHandleStackTraces()!.length;

      final completer = Completer<ImageInfo>();
      final provider = _SharedManualImageProvider(completer);

      late final TileImage second;
      var secondDisposed = false;

      // Two tiles sharing one ImageStreamCompleter, which is what ImageCache
      // does whenever two tiles resolve equal keys — e.g. a tile that leaves
      // the viewport and comes back while its image is still in flight.
      //
      // `ImageStreamCompleter.setImage` dispatches over a COPY of its listener
      // list ("Make a copy to allow for concurrent modification"), so removing
      // a listener from inside that loop does not stop it from being called.
      // The first tile's completion runs `onLoadComplete` — which is where
      // flutter_map prunes tiles — disposing the second tile mid-dispatch.
      final first = _tile(
        x: 0,
        provider: provider,
        onLoadComplete: (_) {
          if (secondDisposed) return;
          secondDisposed = true;
          second.dispose();
        },
      );
      second = _tile(x: 1, provider: provider);

      first.load();
      second.load();

      completer.complete(ImageInfo(image: image));
      await tester.pump();

      expect(
        secondDisposed,
        isTrue,
        reason: 'the scenario under test never happened',
      );
      expect(
        second.imageInfo,
        isNull,
        reason: 'a disposed tile must not keep an image nobody will paint',
      );
      expect(
        image.debugGetOpenHandleStackTraces(),
        hasLength(baseline + 1),
        reason: 'only the live tile may still hold a handle; the one handed to '
            'the disposed tile must be released',
      );

      first.dispose();
    },
  );
}
