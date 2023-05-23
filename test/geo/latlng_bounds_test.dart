import 'package:flutter_map/src/geo/latlng_bounds.dart';
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
  });
}
