import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('MapCamera.clampZoom', () {
    MapCamera cameraAtZoom(double zoom) => MapCamera(
          crs: const Epsg3857(),
          center: const LatLng(0, 0),
          zoom: zoom,
          rotation: 0,
          nonRotatedSize: const Size(200, 300),
          minZoom: 5,
          maxZoom: 18,
        );

    test('clamps to minZoom / maxZoom', () {
      final camera = cameraAtZoom(10);
      expect(camera.clampZoom(2), 5);
      expect(camera.clampZoom(20), 18);
      expect(camera.clampZoom(12), 12);
    });

    test('keeps the current zoom for non-finite input', () {
      // A non-positive pinch scale during a rapid zoom-out makes math.log
      // produce a non-finite zoom. num.clamp does not sanitise NaN, so without
      // the guard this value would flow into the camera and crash the tile
      // range and marker cluster layers.
      final camera = cameraAtZoom(10);
      expect(camera.clampZoom(double.nan), 10);
      expect(camera.clampZoom(double.infinity), 10);
      expect(camera.clampZoom(double.negativeInfinity), 10);
    });

    test('does not clamp when no min/max is set', () {
      final camera = MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(0, 0),
        zoom: 10,
        rotation: 0,
        nonRotatedSize: const Size(200, 300),
      );
      expect(camera.clampZoom(2), 2);
      expect(camera.clampZoom(20), 20);
      expect(camera.clampZoom(double.nan), 10);
    });
  });
}
