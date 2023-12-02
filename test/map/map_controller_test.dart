import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/latlng.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/map/camera/camera_fit.dart';
import 'package:flutter_map/src/map/controller/map_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils/test_app.dart';

void main() {
  testWidgets('test fit bounds methods', (tester) async {
    final controller = MapController();
    final bounds = LatLngBounds(
      const (lat: 51, lon: 0),
      const (lat: 52, lon: 1),
    );
    const expectedCenter = (lat: 51.50274289405741, lon: 0.49999999999999833);

    await tester.pumpWidget(TestApp(controller: controller));

    {
      final cameraConstraint = CameraFit.bounds(bounds: bounds);
      final expectedBounds = LatLngBounds(
        const (lat: 51.00145915187144, lon: 0.3079873797085076),
        const (lat: 52.001427481787005, lon: 1.298485398623206),
      );
      const expectedZoom = 7.451812751543818;

      controller.fitCamera(cameraConstraint);
      await tester.pump();
      final camera = controller.camera;
      expect(camera.visibleBounds, equals(expectedBounds));
      expect(camera.center, equals(expectedCenter));
      expect(camera.zoom, equals(expectedZoom));
    }

    {
      final cameraConstraint = CameraFit.bounds(
        bounds: bounds,
        forceIntegerZoomLevel: true,
      );

      final expectedBounds = LatLngBounds(
        const (lat: 50.819818262156545, lon: 0.6042480468750001),
        const (lat: 52.1874047455997, lon: 1.5930175781250002),
      );
      const expectedZoom = 7;

      controller.fitCamera(cameraConstraint);
      await tester.pump();
      final camera = controller.camera;
      expect(camera.visibleBounds, equals(expectedBounds));
      expect(camera.center, equals(expectedCenter));
      expect(camera.zoom, equals(expectedZoom));
    }

    {
      final cameraConstraint = CameraFit.insideBounds(
        bounds: bounds,
      );

      final expectedBounds = LatLngBounds(
        const (lat: 51.19148727133182, lon: -6.195044477408375e-13),
        const (lat: 51.8139520195805, lon: 0.999999999999397),
      );
      const expectedZoom = 8.135709286104404;

      controller.fitCamera(cameraConstraint);
      await tester.pump();

      final camera = controller.camera;
      expect(camera.visibleBounds, equals(expectedBounds));
      expect(camera.center, equals(expectedCenter));
      expect(camera.zoom, equals(expectedZoom));
    }

    {
      final cameraConstraint = CameraFit.insideBounds(
        bounds: bounds,
        forceIntegerZoomLevel: true,
      );

      final expectedBounds = LatLngBounds(
        const (lat: 51.33232774035881, lon: 0.22521972656250003),
        const (lat: 51.67425842259517, lon: 0.7745361328125),
      );
      const expectedZoom = 9;

      controller.fitCamera(cameraConstraint);
      await tester.pump();
      final camera = controller.camera;
      expect(camera.visibleBounds, equals(expectedBounds));
      expect(camera.center, equals(expectedCenter));
      expect(camera.zoom, equals(expectedZoom));
    }
  });

  testWidgets('test fit bounds methods with rotation', (tester) async {
    final controller = MapController();
    final bounds = LatLngBounds(
      const (lat: 4.214943, lon: 33.925781),
      const (lat: -1.362176, lon: 29.575195),
    );

    await tester.pumpWidget(TestApp(controller: controller));

    Future<void> testFitBounds({
      required double rotation,
      required CameraFit cameraConstraint,
      required LatLngBounds expectedBounds,
      required LatLng expectedCenter,
      required double expectedZoom,
    }) async {
      controller.rotate(rotation);

      controller.fitCamera(cameraConstraint);
      await tester.pump();
      expect(
        controller.camera.visibleBounds.northWest.lat,
        moreOrLessEquals(expectedBounds.northWest.lat),
      );
      expect(
        controller.camera.visibleBounds.northWest.lon,
        moreOrLessEquals(expectedBounds.northWest.lon),
      );
      expect(
        controller.camera.visibleBounds.southEast.lat,
        moreOrLessEquals(expectedBounds.southEast.lat),
      );
      expect(
        controller.camera.visibleBounds.southEast.lon,
        moreOrLessEquals(expectedBounds.southEast.lon),
      );
      expect(
        controller.camera.center.lat,
        moreOrLessEquals(expectedCenter.lat),
      );
      expect(
        controller.camera.center.lon,
        moreOrLessEquals(expectedCenter.lon),
      );
      expect(controller.camera.zoom, moreOrLessEquals(expectedZoom));
    }

    // Tests with no padding

    await testFitBounds(
      rotation: -360,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const (lat: 4.220875035073316, lon: 28.95466920920177),
        const (lat: -1.3562295282017047, lon: 34.53572340816548),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.655171629288527,
    );
    await testFitBounds(
      rotation: -300,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const (lat: 6.229878688707217, lon: 26.943661553415026),
        const (lat: -3.3298966942067114, lon: 36.517625059412495),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.32657729277294,
    );
    await testFitBounds(
      rotation: -240,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const (lat: 6.229878688707217, lon: 26.943661553415026),
        const (lat: -3.3298966942067114, lon: 36.517625059412495),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.32657729277294,
    );
    await testFitBounds(
      rotation: -180,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const (lat: 4.220875035073316, lon: 28.95466920920177),
        const (lat: -1.3562295282017047, lon: 34.53572340816548),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.655171629288527,
    );
    await testFitBounds(
      rotation: -120,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const (lat: 6.2298786887073065, lon: 26.943661553414902),
        const (lat: -3.329896694206635, lon: 36.517625059412374),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.3265772927729405,
    );
    await testFitBounds(
      rotation: -60,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const (lat: 6.2298786887073065, lon: 26.943661553414902),
        const (lat: -3.329896694206635, lon: 36.517625059412374),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.3265772927729405,
    );
    await testFitBounds(
      rotation: 0,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const (lat: 4.220875035073316, lon: 28.95466920920177),
        const (lat: -1.3562295282017047, lon: 34.53572340816548),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.655171629288527,
    );
    await testFitBounds(
      rotation: 60,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const (lat: 6.229878688707217, lon: 26.943661553415026),
        const (lat: -3.3298966942067114, lon: 36.517625059412495),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.32657729277294,
    );
    await testFitBounds(
      rotation: 120,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const (lat: 6.229878688707217, lon: 26.943661553415026),
        const (lat: -3.3298966942067114, lon: 36.517625059412495),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.32657729277294,
    );
    await testFitBounds(
      rotation: 180,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const (lat: 4.220875035073316, lon: 28.95466920920177),
        const (lat: -1.3562295282017047, lon: 34.53572340816548),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.655171629288527,
    );
    await testFitBounds(
      rotation: 240,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const (lat: 6.229878688706365, lon: 26.94366155341602),
        const (lat: -3.3298966942076276, lon: 36.51762505941353),
      ),
      expectedCenter: const (lat: 1.4280748738291607, lon: 31.75048799999998),
      expectedZoom: 5.3265772927729325,
    );
    await testFitBounds(
      rotation: 300,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const (lat: 6.229878688707217, lon: 26.943661553415026),
        const (lat: -3.3298966942067114, lon: 36.517625059412495),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.32657729277294,
    );
    await testFitBounds(
      rotation: 360,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const (lat: 4.220875035073316, lon: 28.95466920920177),
        const (lat: -1.3562295282017047, lon: 34.53572340816548),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.655171629288527,
    );

    // Tests with symmetric padding

    const symmetricPadding = EdgeInsets.all(12);

    await testFitBounds(
      rotation: -360,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.604066851713044, lon: 28.560190151047802),
        const (lat: -1.732813138431261, lon: 34.902297195324785),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.470747058151099,
    );
    await testFitBounds(
      rotation: -300,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 6.862564855409817, lon: 26.292484184306595),
        const (lat: -3.997225315187129, lon: 37.171988168394705),
      ),
      expectedCenter: const (lat: 1.4280748738291607, lon: 31.75048799999998),
      expectedZoom: 5.142152721635503,
    );
    await testFitBounds(
      rotation: -240,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 6.862564855410326, lon: 26.292484184305955),
        const (lat: -3.9972253151865824, lon: 37.17198816839402),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.142152721635507,
    );
    await testFitBounds(
      rotation: -180,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.6040668517126235, lon: 28.560190151048324),
        const (lat: -1.7328131384316936, lon: 34.9022971953253),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999994),
      expectedZoom: 5.470747058151096,
    );
    await testFitBounds(
      rotation: -120,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 6.862564855410096, lon: 26.292484184306193),
        const (lat: -3.997225315186811, lon: 37.17198816839431),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.142152721635505,
    );
    await testFitBounds(
      rotation: -60,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 6.8625648554105165, lon: 26.292484184305717),
        const (lat: -3.9972253151863786, lon: 37.17198816839379),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.142152721635509,
    );
    await testFitBounds(
      rotation: 0,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.604066851712751, lon: 28.560190151048204),
        const (lat: -1.732813138431579, lon: 34.90229719532515),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.470747058151097,
    );
    await testFitBounds(
      rotation: 60,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 6.862564855410008, lon: 26.292484184306353),
        const (lat: -3.9972253151869386, lon: 37.17198816839443),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.1421527216355045,
    );
    await testFitBounds(
      rotation: 120,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 6.8625648554105165, lon: 26.292484184305717),
        const (lat: -3.9972253151863786, lon: 37.17198816839379),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.142152721635509,
    );
    await testFitBounds(
      rotation: 180,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.6040668517126235, lon: 28.560190151048324),
        const (lat: -1.7328131384316936, lon: 34.9022971953253),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999994),
      expectedZoom: 5.470747058151096,
    );
    await testFitBounds(
      rotation: 240,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 6.862564855410008, lon: 26.292484184306353),
        const (lat: -3.9972253151869386, lon: 37.17198816839443),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.1421527216355045,
    );
    await testFitBounds(
      rotation: 300,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 6.862564855411076, lon: 26.292484184305035),
        const (lat: -3.997225315185781, lon: 37.171988168393064),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.142152721635513,
    );
    await testFitBounds(
      rotation: 360,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.604066851711988, lon: 28.56019015104908),
        const (lat: -1.7328131384323806, lon: 34.902297195326106),
      ),
      expectedCenter: const (lat: 1.4280748738291607, lon: 31.75048799999998),
      expectedZoom: 5.47074705815109,
    );

    // Tests with asymmetric padding

    const asymmetricPadding = EdgeInsets.fromLTRB(12, 12, 24, 24);

    await testFitBounds(
      rotation: -360,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.634132562246874, lon: 28.54085445883965),
        const (lat: -2.1664538621122844, lon: 35.34701811611249),
      ),
      expectedCenter: const (lat: 1.2239447514276816, lon: 31.954672909718134),
      expectedZoom: 5.368867444131886,
    );
    await testFitBounds(
      rotation: -300,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 7.353914452121884, lon: 26.258676859164435),
        const (lat: -4.297341450189851, lon: 37.9342421103809),
      ),
      expectedCenter: const (lat: 1.5218975140385778, lon: 32.10075495753647),
      expectedZoom: 5.040273107616291,
    );
    await testFitBounds(
      rotation: -240,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 7.6081448623143, lon: 26.00226365003461),
        const (lat: -4.041607090303907, lon: 37.677828901251075),
      ),
      expectedCenter: const (lat: 1.7782041854790855, lon: 31.844341748407157),
      expectedZoom: 5.0402731076162945,
    );
    await testFitBounds(
      rotation: -180,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 5.041046797566381, lon: 28.132484639403017),
        const (lat: -1.7583244079256093, lon: 34.93864829667586),
      ),
      expectedCenter: const (lat: 1.63218686735705, lon: 31.546303090281786),
      expectedZoom: 5.3688674441318875,
    );
    await testFitBounds(
      rotation: -120,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 7.184346279929569, lon: 25.53217276663045),
        const (lat: -4.467783700569064, lon: 37.207738017846864),
      ),
      expectedCenter: const (lat: 1.334248403356733, lon: 31.400221042463446),
      expectedZoom: 5.040273107616298,
    );
    await testFitBounds(
      rotation: -60,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 6.929875826124592, lon: 25.788585975760196),
        const (lat: -4.723372343263628, lon: 37.46415122697666),
      ),
      expectedCenter: const (lat: 1.0778922142686074, lon: 31.656634251592763),
      expectedZoom: 5.0402731076162945,
    );
    await testFitBounds(
      rotation: 0,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.63413256224709, lon: 28.540854458839405),
        const (lat: -2.166453862112043, lon: 35.347018116112245),
      ),
      expectedCenter: const (lat: 1.223944751427669, lon: 31.954672909718177),
      expectedZoom: 5.3688674441318875,
    );
    await testFitBounds(
      rotation: 60,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 7.353914452122737, lon: 26.258676859163398),
        const (lat: -4.297341450188935, lon: 37.93424211037982),
      ),
      expectedCenter: const (lat: 1.521897514038616, lon: 32.10075495753647),
      expectedZoom: 5.040273107616298,
    );
    await testFitBounds(
      rotation: 120,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 7.6081448623143, lon: 26.00226365003461),
        const (lat: -4.041607090303907, lon: 37.677828901251075),
      ),
      expectedCenter: const (lat: 1.7782041854790855, lon: 31.8443417484072),
      expectedZoom: 5.0402731076162945,
    );
    await testFitBounds(
      rotation: 180,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 5.041046797566381, lon: 28.132484639403017),
        const (lat: -1.7583244079256093, lon: 34.93864829667586),
      ),
      expectedCenter: const (lat: 1.63218686735705, lon: 31.546303090281786),
      expectedZoom: 5.3688674441318875,
    );
    await testFitBounds(
      rotation: 240,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 7.184346279929569, lon: 25.53217276663045),
        const (lat: -4.467783700569064, lon: 37.207738017846864),
      ),
      expectedCenter: const (lat: 1.334248403356733, lon: 31.40022104246349),
      expectedZoom: 5.040273107616298,
    );
    await testFitBounds(
      rotation: 300,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 6.929875826125113, lon: 25.788585975759595),
        const (lat: -4.7233723432630805, lon: 37.46415122697602),
      ),
      expectedCenter: const (lat: 1.0778922142686453, lon: 31.6566342515928),
      expectedZoom: 5.040273107616299,
    );
    await testFitBounds(
      rotation: 360,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.634132562246874, lon: 28.54085445883965),
        const (lat: -2.1664538621122844, lon: 35.34701811611249),
      ),
      expectedCenter: const (lat: 1.2239447514276816, lon: 31.954672909718134),
      expectedZoom: 5.368867444131886,
    );
  });

  testWidgets('test fit coordinates methods', (tester) async {
    final controller = MapController();
    const coordinates = [
      (lat: 4.214943, lon: 33.925781),
      (lat: 3.480523, lon: 30.844116),
      (lat: -1.362176, lon: 29.575195),
      (lat: -0.999705, lon: 33.925781),
    ];

    await tester.pumpWidget(TestApp(controller: controller));

    Future<void> testFitCoordinates({
      required double rotation,
      required FitCoordinates fitCoordinates,
      required LatLng expectedCenter,
      required double expectedZoom,
    }) async {
      controller.rotate(rotation);

      controller.fitCamera(fitCoordinates);
      await tester.pump();
      expect(
        controller.camera.center.lat,
        moreOrLessEquals(expectedCenter.lat),
      );
      expect(
        controller.camera.center.lon,
        moreOrLessEquals(expectedCenter.lon),
      );
      expect(controller.camera.zoom, moreOrLessEquals(expectedZoom));
    }

    FitCoordinates fitCoordinates({
      EdgeInsets padding = EdgeInsets.zero,
    }) =>
        CameraFit.coordinates(
          coordinates: coordinates,
          padding: padding,
        ) as FitCoordinates;

    // Tests with no padding

    await testFitCoordinates(
      rotation: 45,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const (lat: 1.0175550985081283, lon: 32.16110216543986),
      expectedZoom: 5.323677289246632,
    );
    await testFitCoordinates(
      rotation: 90,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.655171629288528,
    );
    await testFitCoordinates(
      rotation: 135,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const (lat: 1.0175550985081538, lon: 32.16110216543989),
      expectedZoom: 5.323677289246641,
    );
    await testFitCoordinates(
      rotation: 180,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.655171629288529,
    );
    await testFitCoordinates(
      rotation: 225,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const (lat: 1.0175550985080901, lon: 32.16110216543997),
      expectedZoom: 5.323677289246641,
    );
    await testFitCoordinates(
      rotation: 270,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.655171629288529,
    );
    await testFitCoordinates(
      rotation: 315,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const (lat: 1.0175550985081538, lon: 32.16110216543989),
      expectedZoom: 5.323677289246641,
    );
    await testFitCoordinates(
      rotation: 360,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.655171629288529,
    );

    // Tests with symmetric padding

    const equalPadding = EdgeInsets.all(12);

    await testFitCoordinates(
      rotation: 45,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const (lat: 1.0175550985081538, lon: 32.16110216543986),
      expectedZoom: 5.139252718109209,
    );
    await testFitCoordinates(
      rotation: 90,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.470747058151099,
    );
    await testFitCoordinates(
      rotation: 135,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const (lat: 1.0175550985081538, lon: 32.161102165439935),
      expectedZoom: 5.139252718109208,
    );
    await testFitCoordinates(
      rotation: 180,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.470747058151097,
    );
    await testFitCoordinates(
      rotation: 225,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const (lat: 1.0175550985081157, lon: 32.16110216543997),
      expectedZoom: 5.13925271810921,
    );
    await testFitCoordinates(
      rotation: 270,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.470747058151099,
    );
    await testFitCoordinates(
      rotation: 315,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const (lat: 1.0175550985081538, lon: 32.16110216543986),
      expectedZoom: 5.13925271810921,
    );
    await testFitCoordinates(
      rotation: 360,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 5.470747058151099,
    );

    // Tests with asymmetric padding

    const asymmetricPadding = EdgeInsets.fromLTRB(12, 12, 24, 24);

    await testFitCoordinates(
      rotation: 45,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const (lat: 1.0175550985081665, lon: 32.524454855645835),
      expectedZoom: 5.037373104089995,
    );
    await testFitCoordinates(
      rotation: 90,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const (lat: 1.63218686735705, lon: 31.954672909718134),
      expectedZoom: 5.36886744413189,
    );
    await testFitCoordinates(
      rotation: 135,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const (lat: 1.3808275978186646, lon: 32.16110216543989),
      expectedZoom: 5.037373104089992,
    );
    await testFitCoordinates(
      rotation: 180,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const (lat: 1.63218686735705, lon: 31.546303090281786),
      expectedZoom: 5.3688674441318875,
    );
    await testFitCoordinates(
      rotation: 225,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const (lat: 1.0175550985081283, lon: 31.797749475233953),
      expectedZoom: 5.037373104089987,
    );
    await testFitCoordinates(
      rotation: 270,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const (lat: 1.2239447514276816, lon: 31.546303090281786),
      expectedZoom: 5.368867444131882,
    );
    await testFitCoordinates(
      rotation: 315,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const (lat: 0.6542416853021571, lon: 32.16110216543989),
      expectedZoom: 5.037373104089994,
    );
    await testFitCoordinates(
      rotation: 360,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const (lat: 1.223944751427707, lon: 31.954672909718177),
      expectedZoom: 5.368867444131889,
    );
  });

  testWidgets('test fit inside bounds with rotation', (tester) async {
    final controller = MapController();
    final bounds = LatLngBounds(
      const (lat: 4.214943, lon: 33.925781),
      const (lat: -1.362176, lon: 29.575195),
    );

    await tester.pumpWidget(TestApp(controller: controller));

    Future<void> testFitInsideBounds({
      required double rotation,
      required CameraFit cameraConstraint,
      required LatLngBounds expectedBounds,
      required LatLng expectedCenter,
      required double expectedZoom,
    }) async {
      controller.rotate(rotation);

      controller.fitCamera(cameraConstraint);
      await tester.pump();
      expect(
        controller.camera.visibleBounds.northWest.lat,
        moreOrLessEquals(expectedBounds.northWest.lat),
      );
      expect(
        controller.camera.visibleBounds.northWest.lon,
        moreOrLessEquals(expectedBounds.northWest.lon),
      );
      expect(
        controller.camera.visibleBounds.southEast.lat,
        moreOrLessEquals(expectedBounds.southEast.lat),
      );
      expect(
        controller.camera.visibleBounds.southEast.lon,
        moreOrLessEquals(expectedBounds.southEast.lon),
      );
      expect(
        controller.camera.center.lat,
        moreOrLessEquals(expectedCenter.lat),
      );
      expect(
        controller.camera.center.lon,
        moreOrLessEquals(expectedCenter.lon),
      );
      expect(controller.camera.zoom, moreOrLessEquals(expectedZoom));
    }

    // Tests with no padding

    await testFitInsideBounds(
      rotation: -360,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.6031134233301474, lon: 29.56772762000039),
        const (lat: -0.7450743699315154, lon: 33.9183136200004),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 6.014499548969527,
    );
    await testFitInsideBounds(
      rotation: -300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.614278658020072, lon: 29.56945889748712),
        const (lat: -0.7338878844415404, lon: 33.920044897487124),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447606),
      expectedZoom: 6.464483862446023,
    );
    await testFitInsideBounds(
      rotation: -240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.6142786580207207, lon: 29.56945889748632),
        const (lat: -0.7338878844408534, lon: 33.92004489748633),
      ),
      expectedCenter: const (lat: 1.427411699029666, lon: 31.747848447605964),
      expectedZoom: 6.464483862446028,
    );
    await testFitInsideBounds(
      rotation: -180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.6031134233301474, lon: 29.56772762000039),
        const (lat: -0.7450743699315154, lon: 33.9183136200004),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 6.014499548969527,
    );
    await testFitInsideBounds(
      rotation: -120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.614278658020072, lon: 29.56945889748712),
        const (lat: -0.7338878844415404, lon: 33.920044897487124),
      ),
      expectedCenter: const (lat: 1.4274116990296914, lon: 31.74784844760592),
      expectedZoom: 6.464483862446023,
    );
    await testFitInsideBounds(
      rotation: -60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.6142786580207207, lon: 29.56945889748632),
        const (lat: -0.7338878844408534, lon: 33.92004489748633),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 6.464483862446028,
    );
    await testFitInsideBounds(
      rotation: 0,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.6031134233301474, lon: 29.56772762000039),
        const (lat: -0.7450743699315154, lon: 33.9183136200004),
      ),
      expectedCenter: const (lat: 1.4280748738291353, lon: 31.75048799999998),
      expectedZoom: 6.014499548969527,
    );
    await testFitInsideBounds(
      rotation: 60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.614278658020072, lon: 29.56945889748712),
        const (lat: -0.7338878844415404, lon: 33.920044897487124),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447606),
      expectedZoom: 6.464483862446023,
    );
    await testFitInsideBounds(
      rotation: 120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.6142786580207207, lon: 29.56945889748632),
        const (lat: -0.7338878844408534, lon: 33.92004489748633),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 6.464483862446028,
    );
    await testFitInsideBounds(
      rotation: 180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.6031134233301474, lon: 29.56772762000039),
        const (lat: -0.7450743699315154, lon: 33.9183136200004),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 6.014499548969527,
    );
    await testFitInsideBounds(
      rotation: 240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.614278658020072, lon: 29.56945889748712),
        const (lat: -0.7338878844415404, lon: 33.920044897487124),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.74784844760592),
      expectedZoom: 6.464483862446023,
    );
    await testFitInsideBounds(
      rotation: 300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.6142786580207207, lon: 29.56945889748632),
        const (lat: -0.7338878844408534, lon: 33.92004489748633),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 6.464483862446028,
    );
    await testFitInsideBounds(
      rotation: 360,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.6031134233301474, lon: 29.56772762000039),
        const (lat: -0.7450743699315154, lon: 33.9183136200004),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 6.014499548969527,
    );

    // Tests with symmetric padding

    const equalPadding = EdgeInsets.all(12);

    await testFitInsideBounds(
      rotation: -360,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.8971355052392727, lon: 29.273074295454837),
        const (lat: -1.0436460563295582, lon: 34.21692202272759),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 5.8300749778321,
    );
    await testFitInsideBounds(
      rotation: -300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        (lat: 3.900159833096254, lon: 29.26631356795233),
        const (lat: -1.0406152150025456, lon: 34.21016129522507),
      ),
      expectedCenter: (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 6.280059291308596,
    );
    await testFitInsideBounds(
      rotation: -240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.900159833095936, lon: 29.266313567952732),
        const (lat: -1.0406152150029018, lon: 34.210161295225475),
      ),
      expectedCenter: const (lat: 1.427411699029666, lon: 31.747848447605964),
      expectedZoom: 6.280059291308594,
    );
    await testFitInsideBounds(
      rotation: -180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.897135505240036, lon: 29.273074295453956),
        const (lat: -1.0436460563287566, lon: 34.21692202272667),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 5.830074977832107,
    );
    await testFitInsideBounds(
      rotation: -120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.900159833096941, lon: 29.26631356795153),
        const (lat: -1.0406152150018586, lon: 34.210161295224275),
      ),
      expectedCenter: const (lat: 1.427411699029615, lon: 31.74784844760592),
      expectedZoom: 6.280059291308602,
    );
    await testFitInsideBounds(
      rotation: -60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.9001598330968137, lon: 29.266313567951688),
        const (lat: -1.0406152150019858, lon: 34.21016129522444),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447606),
      expectedZoom: 6.280059291308601,
    );
    await testFitInsideBounds(
      rotation: 0,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.921797222702341, lon: 29.273074295454474),
        (lat: -1.0189308220167805, lon: 34.21692202272719),
      ),
      expectedCenter: (lat: 1.4280748738291607, lon: 31.750488000000022),
      expectedZoom: 5.830074977832103,
    );
    await testFitInsideBounds(
      rotation: 60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.9001598330947402, lon: 29.26631356795413),
        const (lat: -1.0406152150040977, lon: 34.21016129522692),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 6.280059291308584,
    );
    await testFitInsideBounds(
      rotation: 120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.900159833097259, lon: 29.26631356795117),
        const (lat: -1.0406152150015406, lon: 34.21016129522388),
      ),
      expectedCenter: const (lat: 1.427411699029615, lon: 31.74784844760592),
      expectedZoom: 6.280059291308604,
    );
    await testFitInsideBounds(
      rotation: 180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.897135505238624, lon: 29.273074295455597),
        const (lat: -1.0436460563302323, lon: 34.21692202272835),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 5.830074977832095,
    );
    await testFitInsideBounds(
      rotation: 240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.900159833097577, lon: 29.266313567950775),
        const (lat: -1.0406152150011843, lon: 34.21016129522348),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 6.280059291308607,
    );
    await testFitInsideBounds(
      rotation: 300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.900159833095936, lon: 29.266313567952732),
        const (lat: -1.0406152150029018, lon: 34.210161295225475),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 6.280059291308594,
    );
    await testFitInsideBounds(
      rotation: 360,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.897135505240036, lon: 29.273074295453956),
        const (lat: -1.0436460563287566, lon: 34.21692202272667),
      ),
      expectedCenter: const (lat: 1.4274116990296404, lon: 31.747848447605964),
      expectedZoom: 5.830074977832107,
    );

    // Tests with asymmetric padding

    const asymmetricPadding = EdgeInsets.fromLTRB(12, 12, 24, 24);

    await testFitInsideBounds(
      rotation: -360,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.93081962068567, lon: 29.252575414633416),
        const (lat: -1.371554855609733, lon: 34.558168097560255),
      ),
      expectedCenter: const (lat: 1.2682880092901039, lon: 31.90701622809379),
      expectedZoom: 5.728195363812894,
    );
    await testFitInsideBounds(
      rotation: -300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.12285573833763, lon: 29.236827391148324),
        const (lat: -1.179091165662991, lon: 34.5424200740752),
      ),
      expectedCenter: const (lat: 1.4700469435297785, lon: 31.90701622809379),
      expectedZoom: 6.178179677289382,
    );
    await testFitInsideBounds(
      rotation: -240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.239064535667103, lon: 29.12030848890263),
        const (lat: -1.0625945779487183, lon: 34.42590117182947),
      ),
      expectedCenter: const (lat: 1.5865243776059719, lon: 31.790497325848776),
      expectedZoom: 6.178179677289386,
    );
    await testFitInsideBounds(
      rotation: -180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.248344214607476, lon: 28.934239853659207),
        const (lat: -1.0532909733871119, lon: 34.239832536586086),
      ),
      expectedCenter: const (lat: 1.5865243776059845, lon: 31.58868066711818),
      expectedZoom: 5.728195363812884,
    );
    await testFitInsideBounds(
      rotation: -120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.045373737414225, lon: 28.926110318495112),
        const (lat: -1.2567528788718025, lon: 34.23170300142199),
      ),
      expectedCenter: const (lat: 1.3847756639611237, lon: 31.58868066711814),
      expectedZoom: 6.17817967728938,
    );
    await testFitInsideBounds(
      rotation: -60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.9291368844072636, lon: 29.04262922073941),
        const (lat: -1.373241074234739, lon: 34.34822190366625),
      ),
      expectedCenter: const (lat: 1.2682880092901039, lon: 31.70519956936319),
      expectedZoom: 6.1781796772893856,
    );
    await testFitInsideBounds(
      rotation: 0,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.9308196206843724, lon: 29.252575414634972),
        const (lat: -1.3715548556110944, lon: 34.55816809756181),
      ),
      expectedCenter: const (lat: 1.2689512274367805, lon: 31.909655780487807),
      expectedZoom: 5.728195363812883,
    );
    await testFitInsideBounds(
      rotation: 60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.122855738337325, lon: 29.236827391148683),
        const (lat: -1.179091165663309, lon: 34.542420074075565),
      ),
      expectedCenter: const (lat: 1.4700469435298167, lon: 31.90701622809375),
      expectedZoom: 6.178179677289379,
    );
    await testFitInsideBounds(
      rotation: 120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.23906453566681, lon: 29.12030848890299),
        const (lat: -1.0625945779490364, lon: 34.42590117182983),
      ),
      expectedCenter: const (lat: 1.5865243776060227, lon: 31.790497325848737),
      expectedZoom: 6.178179677289384,
    );
    await testFitInsideBounds(
      rotation: 180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.248344214608647, lon: 28.934239853657804),
        const (lat: -1.053290973385865, lon: 34.23983253658464),
      ),
      expectedCenter: const (lat: 1.5865243776059845, lon: 31.58868066711818),
      expectedZoom: 5.728195363812894,
    );
    await testFitInsideBounds(
      rotation: 240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 4.045373737414429, lon: 28.926110318494874),
        const (lat: -1.2567528788715607, lon: 34.23170300142176),
      ),
      expectedCenter: const (lat: 1.3847756639610982, lon: 31.58868066711814),
      expectedZoom: 6.178179677289382,
    );
    await testFitInsideBounds(
      rotation: 300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.9291368844075816, lon: 29.04262922073901),
        const (lat: -1.3732410742343828, lon: 34.348221903665845),
      ),
      expectedCenter: const (lat: 1.2682880092901676, lon: 31.705199569363227),
      expectedZoom: 6.178179677289388,
    );
    await testFitInsideBounds(
      rotation: 360,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const (lat: 3.9308196206847033, lon: 29.252575414634578),
        const (lat: -1.3715548556107255, lon: 34.55816809756141),
      ),
      expectedCenter: const (lat: 1.2682880092901039, lon: 31.90701622809375),
      expectedZoom: 5.728195363812886,
    );
  });
}
