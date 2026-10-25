import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'pitch_reference_data.dart';

MapCamera _cameraOf(ReferenceCamera reference) => MapCamera(
      crs: const Epsg3857(),
      center: LatLng(reference.latitude, reference.longitude),
      zoom: reference.zoom,
      rotation: reference.rotation,
      nonRotatedSize: Size(reference.width, reference.height),
      pitch: reference.pitch,
    );

String _describe(ReferenceCamera reference) =>
    '${reference.width.toInt()}x${reference.height.toInt()} '
    'pitch ${reference.pitch} rotation ${reference.rotation}';

void main() {
  group('matches MapLibre Native', () {
    for (final reference in referenceCameras) {
      test('pixelToScreenTransform, ${_describe(reference)}', () {
        final camera = _cameraOf(reference);
        final transform = camera.pixelToScreenTransform;
        for (final point in reference.points) {
          final screen = MatrixUtils.transformPoint(
            transform,
            camera.projectAtZoom(LatLng(point.latitude, point.longitude)),
          );
          expect(screen.dx, closeTo(point.x, 0.01));
          expect(screen.dy, closeTo(point.y, 0.01));
        }
      });
    }

    for (final reference in referenceCameras) {
      test('latLngToScreenOffset, ${_describe(reference)}', () {
        final camera = _cameraOf(reference);
        for (final point in reference.points) {
          final screen = camera.latLngToScreenOffset(
            LatLng(point.latitude, point.longitude),
          );
          expect(screen.dx, closeTo(point.x, 0.01));
          expect(screen.dy, closeTo(point.y, 0.01));
        }
      });

      test('screenOffsetToLatLng, ${_describe(reference)}', () {
        final camera = _cameraOf(reference);
        for (final point in reference.points) {
          final coordinate =
              camera.screenOffsetToLatLng(Offset(point.x, point.y));
          expect(coordinate.latitude, closeTo(point.latitude, 1e-7));
          expect(coordinate.longitude, closeTo(point.longitude, 1e-7));
        }
      });
    }
  });

  group('pitched projection', () {
    final camera = MapCamera(
      crs: const Epsg3857(),
      center: const LatLng(45.5, -122.6),
      zoom: 10,
      rotation: 30,
      nonRotatedSize: const Size(400, 300),
      pitch: 60,
    );

    test('center point at the viewport center', () {
      final screen = camera.latLngToScreenOffset(camera.center);
      expect(screen.dx, closeTo(200, 1e-9));
      expect(screen.dy, closeTo(150, 1e-9));
    });

    test('round trip', () {
      for (double x = 0; x <= 400; x += 50) {
        for (double y = 0; y <= 300; y += 50) {
          final coordinate = camera.screenOffsetToLatLng(Offset(x, y));
          final screen = camera.latLngToScreenOffset(coordinate);
          expect(screen.dx, closeTo(x, 0.01));
          expect(screen.dy, closeTo(y, 0.01));
          expect(camera.maybeScreenOffsetToLatLng(Offset(x, y)), coordinate);
        }
      }
    });

    test('above the horizon', () {
      const above = Offset(200, -1000);
      expect(camera.maybeScreenOffsetToLatLng(above), isNull);
      final distant = camera.screenOffsetToLatLng(above);
      expect(
        const Distance().distance(camera.center, distant),
        greaterThan(100000),
      );
    });
  });
}
