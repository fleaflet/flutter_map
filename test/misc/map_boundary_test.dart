import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('VisibleEdgeBoundary', () {
    group('minimumZoomFor', () {
      test('rotated', () {
        final mapBoundary = VisibleEdgeBoundary(
          latLngBounds: LatLngBounds(
            const LatLng(-90, -180),
            const LatLng(90, 180),
          ),
        );

        final clamped = mapBoundary.clampCenterZoom(
          crs: const Epsg3857(),
          visibleSize: const CustomPoint<double>(300, 300),
          centerZoom: CenterZoom(
            center: const LatLng(-90, -180),
            zoom: 1,
          ),
        );

        expect(
            clamped,
            isA<CenterZoom>()
                .having((c) => c.center.latitude, 'latitude',
                    closeTo(-59.534, 0.001))
                .having((c) => c.center.longitude, 'longitude',
                    closeTo(-74.531, 0.001))
                .having((c) => c.zoom, 'zoom', 1));
      });
    });
  });
}
