import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

const _captureKey = ValueKey('map capture');

Widget _map({
  MapController? controller,
  MapOptions options = const MapOptions(
    initialCenter: LatLng(0, 0),
    initialZoom: 1,
  ),
  List<Widget> children = const [],
}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox.square(
          dimension: 256,
          child: RepaintBoundary(
            key: _captureKey,
            child: FlutterMap(
              mapController: controller,
              options: options,
              children: children,
            ),
          ),
        ),
      ),
    );

Future<ByteData> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return (await image.toByteData())!;
    } finally {
      image.dispose();
    }
  }))!;
}

int _red(ByteData pixels, int x, int y) => pixels.getUint8((y * 256 + x) * 4);

Future<ui.Image> _whiteImage(WidgetTester tester) async =>
    (await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(const Color(0xFFFFFFFF), BlendMode.src);
      final picture = recorder.endRecording();
      try {
        return await picture.toImage(1, 1);
      } finally {
        picture.dispose();
      }
    }))!;

void main() {
  for (final fade in [false, true]) {
    testWidgets('grid is covered per tile as it loads (fade: $fade)',
        (tester) async {
      final provider = _DeferredTileProvider();
      final white = await _whiteImage(tester);
      addTearDown(white.dispose);

      await tester.pumpWidget(_map(children: [
        TileLayer(
          tileProvider: provider,
          tileDisplay: fade
              ? const TileDisplay.fadeIn(
                  duration: Duration(milliseconds: 200),
                )
              : const TileDisplay.instantaneous(),
        ),
      ]));

      final loading = await _pixels(tester);
      expect(_red(loading, 32, 32), 224);
      expect(_red(loading, 63, 32), lessThan(224));
      expect(_red(loading, 32, 63), lessThan(224));

      // Complete only the top-left tile. Other tiles must keep their grid.
      provider.images[const TileCoordinates(0, 0, 1)]!.complete(white);
      await tester.pump();
      if (fade) {
        await tester.pump(const Duration(milliseconds: 100));
        final fading = await _pixels(tester);
        expect(
            _red(fading, 63, 32), inExclusiveRange(_red(loading, 63, 32), 255));
      }
      await tester.pump(const Duration(milliseconds: 200));

      final partial = await _pixels(tester);
      expect(_red(partial, 63, 32), 255);
      expect(_red(partial, 191, 224), _red(loading, 191, 224));

      for (final image in provider.images.values) {
        if (!image.completer.isCompleted) image.complete(white);
      }
      await tester.pump();
      await tester.pumpAndSettle();

      final loaded = await _pixels(tester);
      expect(loaded.buffer.asUint8List(), everyElement(255));
    });
  }

  testWidgets('loaded fallback tiles stay above the grid while zooming',
      (tester) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    final provider = _DeferredTileProvider();
    final white = await _whiteImage(tester);
    addTearDown(white.dispose);
    await tester.pumpWidget(_map(controller: controller, children: [
      TileLayer(
        tileProvider: provider,
        tileDisplay: const TileDisplay.instantaneous(),
      ),
    ]));
    for (final image in provider.images.values) {
      image.complete(white);
    }
    await tester.pumpAndSettle();

    controller.move(const LatLng(0, 0), 2);
    await tester.pump();
    expect(
        provider.images.keys.any((coordinates) => coordinates.z == 2), isTrue);
    final zooming = await _pixels(tester);
    expect(zooming.buffer.asUint8List(), everyElement(255));
  });

  testWidgets('grid follows panning, fractional zoom and rotation',
      (tester) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_map(controller: controller));

    final camera = controller.camera;
    controller.move(
      camera.unprojectAtZoom(
        camera.projectAtZoom(camera.center) + const Offset(16, 0),
      ),
      camera.zoom,
    );
    await tester.pump();
    final panned = await _pixels(tester);
    expect(_red(panned, 63, 32), 224);
    expect(_red(panned, 47, 32), lessThan(224));

    controller.move(const LatLng(0, 0), 1.5);
    await tester.pump();
    final zoomed = await _pixels(tester);
    // The line left of the center is now 64 * sqrt(2) pixels away.
    expect(_red(zoomed, 37, 32), lessThan(224));
    expect(_red(zoomed, 63, 32), 224);

    controller.move(const LatLng(0, 0), 1);
    controller.rotate(45);
    await tester.pump();
    final rotated = await _pixels(tester);
    expect(_red(rotated, 100, 100), lessThan(224));
    expect(_red(rotated, 100, 110), 224);
    expect(_red(rotated, 0, 0), lessThan(224));
    expect(_red(rotated, 255, 255), lessThan(224));
  });

  testWidgets('grid color, spacing and disabling update on rebuild',
      (tester) async {
    await tester.pumpWidget(_map());
    await tester.pumpWidget(_map(
      options: const MapOptions(
        initialCenter: LatLng(0, 0),
        initialZoom: 1,
        backgroundGridColor: Color(0xFF000000),
        backgroundGridSpacing: 32,
      ),
    ));
    final custom = await _pixels(tester);
    expect(_red(custom, 31, 16), lessThan(150));
    expect(_red(custom, 16, 16), 224);

    await tester.pumpWidget(_map(
      options: const MapOptions(backgroundGridColor: null),
    ));
    final disabled = await _pixels(tester);
    expect(_red(disabled, 31, 16), 224);
    expect(_red(disabled, 63, 32), 224);
  });

  testWidgets('transparent map backgrounds stay transparent', (tester) async {
    await tester.pumpWidget(_map(
      options: const MapOptions(backgroundColor: Color(0x00000000)),
    ));
    final transparent = await _pixels(tester);
    expect(transparent.buffer.asUint8List(), everyElement(0));
  });

  testWidgets('grid does not intercept map taps or drags', (tester) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    var taps = 0;
    await tester.pumpWidget(_map(
      controller: controller,
      options: MapOptions(onTap: (_, __) => taps++),
    ));
    await tester.tap(find.byType(FlutterMap));
    // Allow the map's double-tap recognition window to expire.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(taps, 1);

    final center = controller.camera.center;
    await tester.drag(find.byType(FlutterMap), const Offset(50, 20));
    await tester.pumpAndSettle();
    expect(controller.camera.center, isNot(center));
  });

  test('grid options participate in equality and reject invalid spacing', () {
    const defaults = MapOptions();
    const disabled = MapOptions(backgroundGridColor: null);
    const spacing = MapOptions(backgroundGridSpacing: 32);
    expect(defaults, isNot(disabled));
    expect(defaults, isNot(spacing));
    expect({defaults, disabled, spacing}, hasLength(3));
    for (final invalid in [0.0, -1.0, double.infinity, double.nan]) {
      expect(() => MapOptions(backgroundGridSpacing: invalid),
          throwsAssertionError);
    }
  });
}

class _DeferredTileProvider extends TileProvider {
  final images = <TileCoordinates, _DeferredImage>{};

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      images.putIfAbsent(coordinates, _DeferredImage.new);
}

class _DeferredImage extends ImageProvider<_DeferredImage> {
  final completer = Completer<ImageInfo>();

  void complete(ui.Image image) =>
      completer.complete(ImageInfo(image: image.clone()));

  @override
  Future<_DeferredImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _DeferredImage key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(completer.future);
}
