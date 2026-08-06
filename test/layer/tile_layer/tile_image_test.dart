import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils/test_frame_driver.dart';



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

      final completer = DrivenCompleter();
      final provider = DrivenProvider(completer);

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
      final first = testTileImage(
        provider: provider,
        onLoadComplete: (_) {
          if (secondDisposed) return;
          secondDisposed = true;
          second.dispose();
        },
      );
      second = testTileImage(x: 1, provider: provider);

      first.load();
      second.load();

      completer.emit(ImageInfo(image: image));
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
    'replacing a frame frees the previous handle — painted or not',
    (tester) async {
      // Ownership truth (checked against Flutter sources, not assumed):
      // `RawImage` CLONES the image for its `RenderImage` — both
      // `createRenderObject` and `updateRenderObject` pass `image?.clone()`.
      // So the render object only ever frees its own clone, and the tile's
      // handle stays the tile's forever. The earlier model ("the render
      // object takes over at build time") was wrong and leaked one handle
      // per painted frame — measured on device as ~0.3/tile after the
      // flag-based fix, because the flag exempted exactly the painted frames.
      final first =
          (await tester.runAsync(() => createTestImage(width: 8, height: 8, cache: false)))!;
      final second =
          (await tester.runAsync(() => createTestImage(width: 9, height: 9, cache: false)))!;
      final base1 = first.debugGetOpenHandleStackTraces()!.length;

      final completer = DrivenCompleter();
      final tile = testTileImage(provider: DrivenProvider(completer));
      tile.load();

      completer.emit(ImageInfo(image: first));
      expect(
        first.debugGetOpenHandleStackTraces()!.length,
        greaterThan(base1),
        reason: 'the tile must hold the first frame — the scenario needs that',
      );

      completer.emit(ImageInfo(image: second));

      expect(
        first.debugGetOpenHandleStackTraces(),
        hasLength(base1 - 1),
        reason: 'on replacement the tile must free its own handle to the '
            'previous frame; the completer freed the original at setImage, '
            'hence one below baseline',
      );

      tile.dispose();
    },
  );

  testWidgets(
    'dispose frees the current handle and nulls the field',
    (tester) async {
      final image =
          (await tester.runAsync(() => createTestImage(width: 8, height: 8, cache: false)))!;
      final baseline = image.debugGetOpenHandleStackTraces()!.length;

      final completer = DrivenCompleter();
      final tile = testTileImage(provider: DrivenProvider(completer));
      tile.load();
      completer.emit(ImageInfo(image: image));

      tile.dispose();

      expect(
        image.debugGetOpenHandleStackTraces(),
        hasLength(baseline),
        reason: 'the tile owned its handle to the very end — dispose must '
            'free it (the completer still holds the original it was given)',
      );
      expect(
        tile.imageInfo,
        isNull,
        reason: 'dispose can race the layer rebuild; a straggler build must '
            'see null (paint nothing), not a disposed image it would clone',
      );
    },
  );
}
