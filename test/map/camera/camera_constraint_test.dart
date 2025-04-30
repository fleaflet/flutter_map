import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('CameraConstraint', () {
    group('contain', () {
      test('rotated', () {
        final mapConstraint = CameraConstraint.contain(
          bounds: LatLngBounds(
            const LatLng(-90, -180),
            const LatLng(90, 180),
          ),
        );

        final camera = MapCamera(
          crs: const Epsg3857(),
          center: const LatLng(-90, -180),
          zoom: 1,
          rotation: 45,
          nonRotatedSize: const Size(200, 300),
        );

        final clamped = mapConstraint.constrain(camera)!;

        expect(clamped.zoom, 1);
        expect(clamped.center.latitude, closeTo(-48.562, 0.001));
        expect(clamped.center.longitude, closeTo(-55.703, 0.001));
      });
    });

    group('containVertically', () {
      test('western longitude', () {
        const mapConstraint = CameraConstraint.containLatitude();

        final camera = MapCamera(
          crs: const Epsg3857(),
          center: const LatLng(0, -179.9),
          zoom: 1,
          rotation: 0,
          nonRotatedSize: const Size(200, 300),
        );

        final clamped = mapConstraint.constrain(camera)!;

        expect(clamped.zoom, 1);
        expect(clamped.center.latitude, closeTo(0, 0.001));
        expect(clamped.center.longitude, closeTo(-179.9, 0.001));
      });
    });

    test('top right corner', () {
      const mapConstraint = CameraConstraint.containLatitude();

      final camera = MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(-90, 179),
        zoom: 1,
        rotation: 0,
        nonRotatedSize: const Size(200, 300),
      );

      final clamped = mapConstraint.constrain(camera)!;

      expect(clamped.zoom, 1);
      expect(clamped.center.latitude, closeTo(-59.534, 0.001));
      expect(clamped.center.longitude, closeTo(179, 0.001));
    });

    test('northern hemisphere', () {
      const mapConstraint = CameraConstraint.containLatitude(0, 90);

      final camera = MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(-10, 179),
        zoom: 2,
        rotation: 0,
        nonRotatedSize: const Size(200, 300),
      );

      final clamped = mapConstraint.constrain(camera)!;

      expect(clamped.zoom, 2);
      expect(clamped.center.latitude, closeTo(46.558, 0.001));
      expect(clamped.center.longitude, closeTo(179, 0.001));
    });

    test('can not translate camera within bounds', () {
      const mapConstraint = CameraConstraint.containLatitude(0, 90);

      final camera = MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(60, 179),
        zoom: 1,
        rotation: 0,
        nonRotatedSize: const Size(200, 300),
      );

      final clamped = mapConstraint.constrain(camera);

      expect(clamped, isNull);
    });
  });
}
