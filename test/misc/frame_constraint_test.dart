import 'package:flutter_map/src/geo/crs.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/map/camera.dart';
import 'package:flutter_map/src/misc/camera_constraint.dart';
import 'package:flutter_map/src/misc/point.dart';
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

        final mapCamera = MapCamera(
          crs: const Epsg3857(),
          center: const LatLng(-90, -180),
          zoom: 1,
          rotation: 45,
          nonRotatedSize: const CustomPoint(200, 300),
        );

        final clamped = mapConstraint.constrain(mapCamera)!;

        expect(clamped.zoom, 1);
        expect(clamped.center.latitude, closeTo(-48.562, 0.001));
        expect(clamped.center.longitude, closeTo(-55.703, 0.001));
      });
    });
  });
}
