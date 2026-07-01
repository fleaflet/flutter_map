import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('LatLngBounds', () {
    const london = LatLng(51.5, -0.09);
    const paris = LatLng(48.8566, 2.3522);
    const dublin = LatLng(53.3498, -6.2603);

    group('LatLngBounds constructor', () {
      test('with dublin, paris', () {
        final bounds = LatLngBounds(dublin, paris);

        expect(bounds, LatLngBounds.fromPoints([dublin, paris]));
      });
    });

    group('LatLngBounds.fromPoints', () {
      test('throw AssertionError if points is empty', () {
        expect(() => LatLngBounds.fromPoints([]), throwsAssertionError);
      });

      test('with dublin, paris, london', () {
        final bounds = LatLngBounds.fromPoints([
          dublin,
          paris,
          london,
        ]);

        final sw = bounds.southWest;
        final ne = bounds.northEast;

        expect(sw.latitude, 48.8566);
        expect(sw.longitude, -6.2603);
        expect(ne.latitude, 53.3498);
        expect(ne.longitude, 2.3522);
      });
    });

    group('hashCode', () {
      test('with dublin, paris', () {
        final bounds1 = LatLngBounds(dublin, paris);
        final bounds2 = LatLngBounds(dublin, paris);

        expect(bounds1 == bounds2, isTrue);
        expect(bounds1.hashCode, bounds2.hashCode);
      });
    });

    group('center', () {
      // cf. https://github.com/fleaflet/flutter_map/issues/1689
      test('should calculate center point #1', () async {
        final bounds = LatLngBounds(
          const LatLng(-77.45, -171.16),
          const LatLng(46.64, 25.88),
        );
        final center = bounds.center;
        expect(center.latitude, greaterThanOrEqualTo(-90));
        expect(center.latitude, lessThanOrEqualTo(90));
        expect(center.longitude, greaterThanOrEqualTo(-180));
        expect(center.longitude, lessThanOrEqualTo(180));
      });
      test('should calculate center point #2', () async {
        final bounds = LatLngBounds(
          const LatLng(-0.87, -179.86),
          const LatLng(84.92, 23.86),
        );
        final center = bounds.center;
        expect(center.latitude, greaterThanOrEqualTo(-90));
        expect(center.latitude, lessThanOrEqualTo(90));
        expect(center.longitude, greaterThanOrEqualTo(-180));
        expect(center.longitude, lessThanOrEqualTo(180));
      });
    });

    group('simpleCenter', () {
      test('should calculate center point #1', () async {
        final bounds = LatLngBounds(
          const LatLng(-77.45, -171.16),
          const LatLng(46.64, 25.88),
        );
        final center = bounds.simpleCenter;
        expect(center.latitude, (-77.45 + 46.64) / 2);
        expect(center.longitude, (-171.16 + 25.88) / 2);
      });
      test('should calculate center point #2', () async {
        final bounds = LatLngBounds(
          const LatLng(-0.87, -179.86),
          const LatLng(84.92, 23.86),
        );
        final center = bounds.simpleCenter;
        expect(center.latitude, (-0.87 + 84.92) / 2);
        expect(center.longitude, (-179.86 + 23.86) / 2);
      });
    });

    group('isOverlapping', () {
      test('should not overlap', () {
        final bounds1 = LatLngBounds(
          const LatLng(49.622376, 18.286332),
          const LatLng(48.721399, 20.122905),
        );
        final bounds2 = LatLngBounds(
          const LatLng(49.33295874620594, 20.58826958952466),
          const LatLng(49.22512969150049, 20.676160214524646),
        );

        expect(bounds1.isOverlapping(bounds2), isFalse);
        expect(bounds2.isOverlapping(bounds1), isFalse);
      });

      test('should overlap', () {
        final bounds1 = LatLngBounds(
          const LatLng(50, 20),
          const LatLng(51, 21),
        );
        final bounds2 = LatLngBounds(
          const LatLng(50.5, 20.5),
          const LatLng(51.5, 21.5),
        );

        expect(bounds1.isOverlapping(bounds2), isTrue);
        expect(bounds2.isOverlapping(bounds1), isTrue);
      });
    });
  });
}
