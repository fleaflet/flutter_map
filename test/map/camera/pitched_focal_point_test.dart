import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

MapCamera _camera({double pitch = 50}) => MapCamera(
      crs: const Epsg3857(),
      center: const LatLng(45.5, -122.6),
      zoom: 10,
      rotation: 30,
      nonRotatedSize: const Size(400, 300),
      pitch: pitch,
    );

void main() {
  for (final focal in const [
    Offset(320, 20),
    Offset(60, 280),
    Offset(200, 5)
  ]) {
    for (final zoom in [11.5, 8.25]) {
      test('focusedZoomCenter keeps the coordinate at $focal, zoom $zoom', () {
        final camera = _camera();
        final coordinate = camera.screenOffsetToLatLng(focal);
        final zoomed = camera.withPosition(
          center: camera.focusedZoomCenter(focal, zoom),
          zoom: zoom,
        );
        final screen = zoomed.latLngToScreenOffset(coordinate);
        expect((screen - focal).distance, lessThan(0.5));
      });
    }
  }

  test('focusedZoomCenter keeps the center above the horizon', () {
    final camera = _camera();
    expect(
        camera.focusedZoomCenter(const Offset(200, -1000), 12), camera.center);
  });

  test('offsetToCrs is the coordinate under the offset', () {
    final camera = _camera();
    for (final offset in const [Offset(320, 20), Offset(60, 280)]) {
      final coordinate = camera.offsetToCrs(offset);
      final expected = camera.screenOffsetToLatLng(offset);
      expect(coordinate.latitude, closeTo(expected.latitude, 1e-9));
      expect(coordinate.longitude, closeTo(expected.longitude, 1e-9));
    }
  });

  test('offsetToCrs and focusedZoomCenter at pitch 0 are unchanged', () {
    final camera = _camera(pitch: 0);
    const offset = Offset(320, 20);
    final rotated = offset - const Offset(200, 150);
    final angle = camera.rotationRad;
    final ground = Offset(
      rotated.dx * cos(angle) + rotated.dy * sin(angle),
      rotated.dy * cos(angle) - rotated.dx * sin(angle),
    );
    final center = camera.projectAtZoom(camera.center);
    expect(camera.offsetToCrs(offset), camera.unprojectAtZoom(center + ground));
    final scale = camera.getZoomScale(12, 10);
    expect(
      camera.focusedZoomCenter(offset, 12),
      camera.unprojectAtZoom(center + ground * (1 - 1 / scale)),
    );
  });
}
