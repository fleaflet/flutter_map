import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('LatLngBounds', () {
    final london = LatLng(51.5, -0.09);
    final paris = LatLng(48.8566, 2.3522);
    final dublin = LatLng(53.3498, -6.2603);

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
  });
}
