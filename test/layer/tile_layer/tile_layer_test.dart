import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../test_utils/test_tile_image.dart';

void main() {
  const center = LatLng(45.5231, -122.6765);

  // Decoding does not finish under the fake clock of widget tests, so tiles
  // are served already decoded.
  late ui.Image tileImage;
  setUpAll(
      () async => tileImage = await createTestImage(width: 256, height: 256));

  TileProvider failingAboveZoom3() =>
      _FailingAboveZoomTileProvider(maxZoom: 3, image: tileImage);

  Future<MapController> pumpMap(
    WidgetTester tester,
    TileLayer tileLayer,
  ) async {
    final controller = MapController();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: FlutterMap(
              mapController: controller,
              options: const MapOptions(initialCenter: center, initialZoom: 3),
              children: [tileLayer],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  Iterable<TileImage> tilesDrawn(WidgetTester tester) =>
      tester.widgetList<Tile>(find.byType(Tile)).map((tile) => tile.tileImage);

  group('tiles fail to load after zooming in', () {
    Future<void> zoomIn(WidgetTester tester, MapController controller) async {
      controller.move(center, 5);
      await tester.pumpAndSettle();
    }

    testWidgets('without errorImage - tiles of the previous zoom still drawn',
        (tester) async {
      final controller = await pumpMap(
        tester,
        TileLayer(tileProvider: failingAboveZoom3()),
      );

      await zoomIn(tester, controller);

      final drawn = tilesDrawn(tester);
      expect(drawn.where((tile) => tile.coordinates.z == 5), isNotEmpty);
      expect(drawn.where((tile) => tile.coordinates.z == 5 && tile.loadError),
          isNotEmpty);
      expect(drawn.where((tile) => tile.coordinates.z == 3), isNotEmpty);
    });

    testWidgets(
        'with tileBuilder - builder gets the failed tiles, '
        'tiles of the previous zoom still drawn', (tester) async {
      final builtWithError = <TileCoordinates>{};
      final controller = await pumpMap(
        tester,
        TileLayer(
          tileProvider: failingAboveZoom3(),
          tileBuilder: (context, tileWidget, tile) {
            if (tile.loadError) builtWithError.add(tile.coordinates);
            return tileWidget;
          },
        ),
      );

      await zoomIn(tester, controller);

      expect(builtWithError, isNotEmpty);
      expect(
          builtWithError.map((coordinates) => coordinates.z), everyElement(5));
      expect(
        tilesDrawn(tester).where((tile) => tile.coordinates.z == 3),
        isNotEmpty,
      );
    });

    testWidgets('with errorImage - error image drawn instead', (tester) async {
      final controller = await pumpMap(
        tester,
        TileLayer(
          tileProvider: failingAboveZoom3(),
          errorImage: testWhiteTileImage,
        ),
      );

      await zoomIn(tester, controller);

      final drawn = tilesDrawn(tester);
      expect(drawn.where((tile) => tile.coordinates.z == 5),
          everyElement(predicate<TileImage>((tile) => tile.readyToDisplay)));
      expect(drawn.where((tile) => tile.coordinates.z == 3), isEmpty);
    });
  });
}

/// Serves tiles up to [maxZoom], like a cache would without a connection,
/// and fails above it.
class _FailingAboveZoomTileProvider extends TileProvider {
  _FailingAboveZoomTileProvider({required this.maxZoom, required this.image});

  final int maxZoom;
  final ui.Image image;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _TileImageProvider(coordinates, coordinates.z <= maxZoom ? image : null);
}

class _TileImageProvider extends ImageProvider<_TileImageProvider> {
  const _TileImageProvider(this.coordinates, this.image);

  final TileCoordinates coordinates;

  /// Null for a tile that fails to load.
  final ui.Image? image;

  @override
  Future<_TileImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _TileImageProvider key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(
        switch (image) {
          final image? => SynchronousFuture(ImageInfo(image: image.clone())),
          null => Future<ImageInfo>.error(Exception('No connection')),
        },
      );

  @override
  bool operator ==(Object other) =>
      other is _TileImageProvider && other.coordinates == coordinates;

  @override
  int get hashCode => coordinates.hashCode;
}
