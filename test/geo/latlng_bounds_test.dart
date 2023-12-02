import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LatLngBounds', () {
    const london = (lat: 51.5, lon: 0.09);
    const paris = (lat: 48.8566, lon: 2.3522);
    const dublin = (lat: 53.3498, lon: 6.2603);

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

        expect(sw.lat, 48.8566);
        expect(sw.lon, -6.2603);
        expect(ne.lat, 53.3498);
        expect(ne.lon, 2.3522);
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
