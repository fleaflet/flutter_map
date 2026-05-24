import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../test_utils/test_app.dart';

void main() {
  group('isFiniteMapLatLng', () {
    test('returns true for normal coordinates', () {
      expect(isFiniteMapLatLng(const LatLng(51.5, -0.09)), isTrue);
    });

    test('returns false for NaN and infinity', () {
      expect(isFiniteMapLatLng(const LatLng(double.nan, 0)), isFalse);
      expect(isFiniteMapLatLng(const LatLng(0, double.nan)), isFalse);
      expect(isFiniteMapLatLng(const LatLng(double.infinity, 0)), isFalse);
    });
  });

  group('MapCamera.focusedZoomCenter', () {
    const center = LatLng(40.7128, -74.006);

    MapCamera camera({
      required Size size,
      double zoom = 12,
    }) =>
        MapCamera(
          crs: const Epsg3857(),
          center: center,
          zoom: zoom,
          rotation: 0,
          nonRotatedSize: size,
        );

    test('returns current center before layout size is known', () {
      final cam = MapCamera.initialCamera(
        const MapOptions(
          initialCenter: center,
          initialZoom: 12,
        ),
      );

      expect(cam.nonRotatedSize, MapCamera.kImpossibleSize);
      expect(
        cam.focusedZoomCenter(const Offset(100, 100), 5.5),
        cam.center,
      );
    });

    test('returns current center for non-finite target zoom', () {
      final cam = camera(size: const Size(400, 600));
      expect(
        cam.focusedZoomCenter(const Offset(200, 300), double.nan),
        center,
      );
    });

    test('returns current center for invalid viewport size', () {
      final cam = camera(size: const Size(0, 600));
      expect(
        cam.focusedZoomCenter(const Offset(0, 0), 8),
        center,
      );
    });

    test('returns finite coordinates when cursor is at viewport center', () {
      final cam = camera(size: const Size(400, 600));
      final result = cam.focusedZoomCenter(
        const Offset(200, 300),
        12,
      );
      expect(isFiniteMapLatLng(result), isTrue);
      expect(result.latitude, closeTo(center.latitude, 0.0001));
      expect(result.longitude, closeTo(center.longitude, 0.0001));
    });

    test('returns finite coordinates when zooming out toward min zoom', () {
      final cam = camera(size: const Size(400, 600), zoom: 14);
      final result = cam.focusedZoomCenter(const Offset(50, 80), 5.5);
      expect(isFiniteMapLatLng(result), isTrue);
      expect(() => cam.projectAtZoom(result, 5.5), returnsNormally);
    });
  });

  group('MapController.move', () {
    testWidgets('rejects non-finite center and leaves camera unchanged', (
      tester,
    ) async {
      final controller = MapController();
      await tester.pumpWidget(TestApp(controller: controller));
      await tester.pump();

      final beforeCenter = controller.camera.center;
      final beforeZoom = controller.camera.zoom;

      expect(
        controller.move(const LatLng(double.nan, double.nan), beforeZoom),
        isFalse,
      );
      expect(controller.camera.center, beforeCenter);
      expect(controller.camera.zoom, beforeZoom);
      expect(isFiniteMapLatLng(controller.camera.center), isTrue);
    });

    testWidgets('rejects non-finite zoom', (tester) async {
      final controller = MapController();
      await tester.pumpWidget(TestApp(controller: controller));
      await tester.pump();

      final before = controller.camera.center;

      expect(
        controller.move(before, double.nan),
        isFalse,
      );
      expect(controller.camera.center, before);
    });
  });

  group('TileRangeCalculator', () {
    test('calculate succeeds with finite map center', () {
      const calculator = TileRangeCalculator(tileDimension: 256);
      final camera = MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(51.5, -0.09),
        zoom: 10,
        rotation: 0,
        nonRotatedSize: const Size(400, 400),
      );

      expect(
        () => calculator.calculate(camera: camera, tileZoom: 10),
        returnsNormally,
      );
    });

    test('calculate throws when center is non-finite', () {
      const calculator = TileRangeCalculator(tileDimension: 256);
      final camera = MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(double.nan, double.nan),
        zoom: 10,
        rotation: 0,
        nonRotatedSize: const Size(400, 400),
      );

      expect(
        () => calculator.calculate(camera: camera, tileZoom: 10),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('LatLng is not finite'),
          ),
        ),
      );
    });
  });
}
