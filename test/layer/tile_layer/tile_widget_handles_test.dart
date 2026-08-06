import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile.dart';
import 'package:flutter_test/flutter_test.dart';

/// Handle accounting through the FULL widget cycle: TileImage → Tile →
/// RawImage → RenderImage.
///
/// This is the test that CAUGHT the second leak (0806): the flag-based fix
/// assumed `RawImage` hands ownership to `RenderImage` at build time. It does
/// not — `RawImage` CLONES for the render object, so the tile's own handle
/// stayed open forever on every painted frame (~0.3/tile on device after the
/// flag fix, because the flag exempted exactly the painted frames).
///
/// Pure-TileImage tests can't see this: the bug lived in what the widget
/// integration does NOT do with the handle. Hence full cycle here, counting
/// OPEN HANDLES on the raw images after complete teardown — not code presence.
///
/// ⚠️ `cache: false` and DIFFERENT sizes are load-bearing: `createTestImage`
/// caches by size and returns clones of one shared image, which makes two
/// "independent" counters move in lockstep and hides per-frame attribution.
class _DrivenCompleter extends ImageStreamCompleter {
  void emit(ImageInfo info) => setImage(info);
}

class _DrivenProvider extends ImageProvider<_DrivenProvider> {
  _DrivenProvider(this.completer);

  final _DrivenCompleter completer;

  @override
  Future<_DrivenProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_DrivenProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    _DrivenProvider key,
    ImageDecoderCallback decode,
  ) =>
      completer;
}

TileImage _tileImage(ImageProvider provider) => TileImage(
      vsync: const TestVSync(),
      coordinates: const TileCoordinates(0, 0, 0),
      imageProvider: provider,
      onLoadComplete: (_) {},
      onLoadError: (_, __, ___) {},
      tileDisplay: const TileDisplay.instantaneous(),
      errorImage: null,
      cancelLoading: Completer<void>(),
    );

Widget _host(TileImage tileImage) => Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Tile(
            scaledTileDimension: 256,
            currentPixelOrigin: Offset.zero,
            tileImage: tileImage,
            tileBuilder: null,
            positionCoordinates: const TileCoordinates(0, 0, 0),
          ),
        ],
      ),
    );

void main() {
  testWidgets(
    'two frames with a build in between: after unmount every handle is closed',
    (tester) async {
      final images = (await tester.runAsync(() async => [
            await createTestImage(width: 8, height: 8, cache: false),
            await createTestImage(width: 9, height: 9, cache: false),
          ]))!;
      final base1 = images[0].debugGetOpenHandleStackTraces()!.length;
      final base2 = images[1].debugGetOpenHandleStackTraces()!.length;

      final completer = _DrivenCompleter();
      final tileImage = _tileImage(_DrivenProvider(completer));
      tileImage.load();

      await tester.pumpWidget(_host(tileImage));

      // Frame 1, then a real build (the widget hands the handle on), then
      // frame 2, then another build.
      completer.emit(ImageInfo(image: images[0]));
      await tester.pump();
      completer.emit(ImageInfo(image: images[1]));
      await tester.pump();

      // Tile leaves the tree (prune) and the TileImage is disposed — the full
      // real-life teardown.
      await tester.pumpWidget(const SizedBox());
      tileImage.dispose();
      // The completer outlives the tile in reality only while ImageCache holds
      // it; here nobody does, so its current image must go too.

      expect(
        images[0].debugGetOpenHandleStackTraces(),
        hasLength(base1 - 1),
        reason: 'frame 1: the completer freed the original at setImage and '
            'the tile freed its clone on replacement — after teardown NOTHING '
            'may hold it (this exact assertion caught the flag-based leak)',
      );
      expect(
        images[1].debugGetOpenHandleStackTraces(),
        hasLength(base2),
        reason: 'frame 2: the only open handle is the ORIGINAL one, now owned '
            'by the completer as its current image (ImageCache would own the '
            'completer in production) — the tile\'s clone must be gone',
      );
    },
  );

  testWidgets(
    'two frames in the SAME frame budget: after unmount every handle is closed',
    (tester) async {
      final images = (await tester.runAsync(() async => [
            await createTestImage(width: 8, height: 8, cache: false),
            await createTestImage(width: 9, height: 9, cache: false),
          ]))!;
      final base1 = images[0].debugGetOpenHandleStackTraces()!.length;
      final base2 = images[1].debugGetOpenHandleStackTraces()!.length;

      final completer = _DrivenCompleter();
      final tileImage = _tileImage(_DrivenProvider(completer));
      tileImage.load();
      await tester.pumpWidget(_host(tileImage));

      // Both frames before any pump — the fast-device case that leaked.
      completer.emit(ImageInfo(image: images[0]));
      completer.emit(ImageInfo(image: images[1]));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      tileImage.dispose();

      expect(
        images[0].debugGetOpenHandleStackTraces(),
        hasLength(base1 - 1),
        reason: 'frame 1: no build between frames — same rule, the tile frees '
            'its own handle on replacement',
      );
      expect(
        images[1].debugGetOpenHandleStackTraces(),
        hasLength(base2),
        reason: 'frame 2: only the original handle (completer-owned) remains',
      );
    },
  );

  testWidgets(
    'tile pruned between the frames: after teardown every handle is closed',
    (tester) async {
      final images = (await tester.runAsync(() async => [
            await createTestImage(width: 8, height: 8, cache: false),
            await createTestImage(width: 9, height: 9, cache: false),
          ]))!;
      final base1 = images[0].debugGetOpenHandleStackTraces()!.length;
      final base2 = images[1].debugGetOpenHandleStackTraces()!.length;

      final completer = _DrivenCompleter();
      final tileImage = _tileImage(_DrivenProvider(completer));
      tileImage.load();
      await tester.pumpWidget(_host(tileImage));

      completer.emit(ImageInfo(image: images[0]));
      await tester.pump();

      // Prune happens NOW — then the (shared, cache-held) completer still
      // delivers frame 2 to nobody.
      await tester.pumpWidget(const SizedBox());
      tileImage.dispose();
      completer.emit(ImageInfo(image: images[1]));

      expect(
        images[0].debugGetOpenHandleStackTraces(),
        hasLength(base1 - 1),
        reason: 'frame 1 went through a build; teardown must close every '
            'handle to it',
      );
      expect(
        images[1].debugGetOpenHandleStackTraces(),
        hasLength(base2),
        reason: 'frame 2: only the original handle (completer-owned) remains '
            '— delivered to nobody, cloned by nobody',
      );
    },
  );
}
