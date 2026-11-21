import 'dart:math' show Point;
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;

void main() {
  // A simple synthetic CRS with a finite, evenly-spaced (in log space)
  // resolutions list. `_scales` is `1 / resolution`, so scales are
  // [1/4096, 1/2048, 1/1024, 1/512, 1/256] for zoom levels 0..4.
  Proj4Crs makeCrs() => Proj4Crs.fromFactory(
        code: 'EPSG:3978',
        proj4Projection: proj4.Projection.add(
          'EPSG:3978',
          '+proj=lcc +lat_0=49 +lon_0=-95 +lat_1=49 +lat_2=77 +x_0=0 +y_0=0 '
              '+ellps=GRS80 +units=m +no_defs',
        ),
        resolutions: const [4096.0, 2048.0, 1024.0, 512.0, 256.0],
      );

  group('Proj4Crs.scale', () {
    final crs = makeCrs();

    test('returns the exact scale at integer zoom levels in range', () {
      expect(crs.scale(0), 1 / 4096.0);
      expect(crs.scale(4), 1 / 256.0);
    });

    test('interpolates between adjacent levels', () {
      final expected = 1 / 2048.0 + (1 / 1024.0 - 1 / 2048.0) * 0.5;
      expect(crs.scale(1.5), closeTo(expected, 1e-18));
    });

    test('does not throw for a zoom below the coarsest level (#1358)', () {
      // Before the fix this indexed `_scales[-1]` and threw a RangeError.
      final result = crs.scale(-0.5);
      expect(result.isFinite, isTrue);
    });

    test('does not throw for a zoom above the finest level (#1223)', () {
      // Before the fix this indexed `_scales[iZoom]`/`_scales[iZoom + 1]` past
      // the end of the list and threw a RangeError.
      final result = crs.scale(6.5);
      expect(result.isFinite, isTrue);
    });

    test('is strictly increasing across and beyond the defined range', () {
      double? previous;
      for (var z = -2.0; z <= 7.0; z += 0.25) {
        final s = crs.scale(z);
        expect(s.isFinite, isTrue, reason: 'scale($z) should be finite');
        if (previous != null) {
          expect(s, greaterThan(previous),
              reason: 'scale should increase monotonically with zoom');
        }
        previous = s;
      }
    });
  });

  group('Proj4Crs.zoom', () {
    final crs = makeCrs();

    test('returns the array index when the scale matches a level exactly', () {
      expect(crs.zoom(1 / 4096.0), 0);
      expect(crs.zoom(1 / 256.0), 4);
    });

    test('interpolates between adjacent levels', () {
      final lo = 1 / 2048.0;
      final hi = 1 / 1024.0;
      expect(crs.zoom((lo + hi) / 2), closeTo(1.5, 1e-9));
    });

    test('extrapolates to a finite value below the coarsest level (#1358)', () {
      // Previously returned `double.negativeInfinity`, which threw on any
      // subsequent `.round()`/`.floor()` (e.g. in `_getTransformationByZoom`).
      final result = crs.zoom(1 / 8192.0);
      expect(result.isFinite, isTrue);
      expect(result, lessThan(0));
    });

    test('extrapolates to a finite value above the finest level (#1223)', () {
      // Previously threw a RangeError (and `double.infinity` in the interim
      // fix, which also threw on `.round()`/`.floor()`).
      final result = crs.zoom(1 / 128.0);
      expect(result.isFinite, isTrue);
      expect(result, greaterThan(4));
    });
  });

  group('Proj4Crs scale/zoom round-trip', () {
    final crs = makeCrs();

    test('zoom(scale(z)) == z within and beyond the defined range', () {
      for (final z in const [-0.5, 0.0, 1.5, 3.0, 4.0, 5.5]) {
        expect(crs.zoom(crs.scale(z)), closeTo(z, 1e-9),
            reason: 'round-trip failed at zoom $z');
      }
    });

    test('scale(zoom(s)) == s within and beyond the defined range', () {
      for (final s in const [1 / 8192.0, 1 / 4096.0, 1 / 700.0, 1 / 128.0]) {
        expect(crs.scale(crs.zoom(s)), closeTo(s, 1e-18),
            reason: 'round-trip failed at scale $s');
      }
    });
  });

  group('Proj4Crs transformation with out-of-range zoom', () {
    final crs = makeCrs();

    test('latLngToXY does not throw for an out-of-range zoom', () {
      // `latLngToXY` -> `_getTransformationByZoom(zoom(scale))`; a non-finite
      // or negative intermediate zoom used to throw on `.round()` or index the
      // transformations list out of range.
      expect(() => crs.latLngToXY(const LatLng(46.8, -71.2), crs.scale(6.5)),
          returnsNormally);
      expect(() => crs.latLngToXY(const LatLng(46.8, -71.2), crs.scale(-0.5)),
          returnsNormally);
    });
  });

  group('CameraFit.bounds with a finite-resolution Proj4Crs (#1223)', () {
    // The exact CRS and bounds from issue #1223's reproduction.
    final crs = Proj4Crs.fromFactory(
      code: 'EPSG:2039',
      proj4Projection: proj4.Projection.add(
        'EPSG:2039',
        '+proj=tmerc +lat_0=31.73439361111111 +lon_0=35.20451694444445 '
            '+k=1.0000067 +x_0=219529.584 +y_0=626907.39 +ellps=GRS80 '
            '+towgs84=-48,55,52,0,0,0,0 +units=m +no_defs',
      ),
      resolutions: const <double>[
        793.751587503175,
        264.583862501058,
        132.291931250529,
        66.1459656252646,
        26.4583862501058,
        13.2291931250529,
        6.61459656252646,
        2.64583862501058,
        1.32291931250529,
        0.661459656252646,
        0.330729828126323,
      ],
      origins: const [Point<double>(-5403700, 7116700)],
    );

    test('fitting tiny bounds does not throw and respects maxZoom', () {
      final camera = MapCamera(
        crs: crs,
        center: const LatLng(31.698, 34.934),
        // The default `MapOptions.initialZoom` (13.0) exceeds the deepest
        // level (index 10). `_getBoundsZoom` calls `crs.scale(13.0)` before any
        // clamping, which is where #1223 crashed.
        zoom: 13,
        rotation: 0,
        nonRotatedSize: const Size(600, 800),
      );

      final fit = CameraFit.bounds(
        bounds: LatLngBounds(
          const LatLng(31.699685, 34.936118),
          const LatLng(31.697378, 34.932516),
        ),
        maxZoom: 10,
      );

      late final MapCamera fitted;
      expect(() => fitted = fit.fit(camera), returnsNormally);
      expect(fitted.zoom, lessThanOrEqualTo(10.0));
    });
  });
}
