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

  testWidgets(
    'frees the first frame when a second frame replaces it before any build',
    (tester) async {
      // Ownership of a tile's decoded image transfers at BUILD time: `RawImage`
      // hands the handle to `RenderImage`, which frees it. With one frame per
      // tile that always holds. A completer emitting a second frame can
      // overwrite the first before any build happened — and then nobody frees
      // the first handle. Measured on device: ~0.9 leaked handles per tile,
      // invisible to `ImageCache`.
      final images = (await tester.runAsync(() async => [
            await createTestImage(width: 8, height: 8),
            await createTestImage(width: 8, height: 8),
          ]))!;
      final first = images[0];
      final second = images[1];
      final baseline = first.debugGetOpenHandleStackTraces()!.length;

      final completer = _MultiFrameCompleter();
      final tile = _tile(x: 0, provider: _MultiFrameProvider(completer));
      tile.load();

      completer.emit(ImageInfo(image: first));
      expect(
        first.debugGetOpenHandleStackTraces(),
        hasLength(baseline + 1),
        reason: 'the tile holds the first frame — the scenario needs that',
      );

      // No pump: the second frame lands within the same frame budget, which is
      // the common case on a fast device.
      completer.emit(ImageInfo(image: second));

      expect(
        first.debugGetOpenHandleStackTraces(),
        hasLength(baseline),
        reason: 'no build ever passed the first frame to a RenderImage, so the '
            'tile still owned it and must free it on replacement',
      );

      tile.dispose();
    },
  );

  testWidgets(
    'keeps a frame the widget already handed to the render object',
    (tester) async {
      // The mirror case: freeing a handle a `RenderImage` owns would be a
      // double free. This is what makes the fix above safe rather than lucky.
      final images = (await tester.runAsync(() async => [
            await createTestImage(width: 8, height: 8),
            await createTestImage(width: 8, height: 8),
          ]))!;
      final first = images[0];
      final baseline = first.debugGetOpenHandleStackTraces()!.length;

      final completer = _MultiFrameCompleter();
      final tile = _tile(x: 0, provider: _MultiFrameProvider(completer));
      tile.load();

      completer.emit(ImageInfo(image: first));
      // A build happened: `Tile` passed the handle on.
      tile.markImageHandedToRenderObject();
      completer.emit(ImageInfo(image: images[1]));

      expect(
        first.debugGetOpenHandleStackTraces(),
        hasLength(baseline + 1),
        reason: 'the render object owns this handle now and disposes it when '
            'it is replaced — the tile must keep its hands off',
      );

      tile.dispose();
    },
  );
}

/// A completer the test drives frame by frame — progressive tiles (a base
/// frame followed by a composed one) emit more than once.
class _MultiFrameCompleter extends ImageStreamCompleter {
  void emit(ImageInfo info) => setImage(info);
}

class _MultiFrameProvider extends ImageProvider<_MultiFrameProvider> {
  _MultiFrameProvider(this.completer);

  final _MultiFrameCompleter completer;

  @override
  Future<_MultiFrameProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_MultiFrameProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    _MultiFrameProvider key,
    ImageDecoderCallback decode,
  ) =>
      completer;
}
