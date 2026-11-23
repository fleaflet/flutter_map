import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/test_app.dart';

void main() {
  testWidgets('test fit bounds methods', (tester) async {
    final controller = MapController();
    final bounds = LatLngBounds(
      const LatLng(51, 0),
      const LatLng(52, 1),
    );
    const expectedCenter = LatLng(51.50274289405741, 0.49999999999999833);

    await tester.pumpWidget(TestApp(controller: controller));

    {
      final cameraConstraint = CameraFit.bounds(bounds: bounds);
      final expectedBounds = LatLngBounds(
        const LatLng(50.999999999999986, -0.30323638916584805),
        const LatLng(52, 1.3032363891658447),
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
        const LatLng(50.81372841791738, -0.5986328125000017),
        const LatLng(52.18149496391637, 1.5986328124999982),
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
        const LatLng(51.19044057942834, 5.551115123125783e-17),
        const LatLng(51.81291952783707, 0.9999999999999967),
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
        const LatLng(51.33145357316716, 0.22534179687499833),
        const LatLng(51.67339079014399, 0.7746582031249983),
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
      const LatLng(4.214943, 33.925781),
      const LatLng(-1.362176, 29.575195),
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
        controller.camera.visibleBounds.northWest.latitude,
        moreOrLessEquals(expectedBounds.northWest.latitude),
      );
      expect(
        controller.camera.visibleBounds.northWest.longitude,
        moreOrLessEquals(expectedBounds.northWest.longitude),
      );
      expect(
        controller.camera.visibleBounds.southEast.latitude,
        moreOrLessEquals(expectedBounds.southEast.latitude),
      );
      expect(
        controller.camera.visibleBounds.southEast.longitude,
        moreOrLessEquals(expectedBounds.southEast.longitude),
      );
      expect(
        controller.camera.center.latitude,
        moreOrLessEquals(expectedCenter.latitude),
      );
      expect(
        controller.camera.center.longitude,
        moreOrLessEquals(expectedCenter.longitude),
      );
      expect(controller.camera.zoom, moreOrLessEquals(expectedZoom));
    }

    // Tests with no padding

    await testFitBounds(
      rotation: -360,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const LatLng(4.214943000000034, 28.959960900518126),
        const LatLng(-1.3621759999999445, 34.54101509948183),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.655171629288527,
    );
    await testFitBounds(
      rotation: -300,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const LatLng(6.203051199630898, 26.96350624700129),
        const LatLng(-3.3568369334869494, 36.53746975299875),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.32657729277294,
    );
    await testFitBounds(
      rotation: -240,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const LatLng(6.203051199630923, 26.963506247001227),
        const LatLng(-3.3568369334869494, 36.53746975299873),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.32657729277294,
    );
    await testFitBounds(
      rotation: -180,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const LatLng(4.214943000000009, 28.959960900518112),
        const LatLng(-1.3621759999999827, 34.54101509948185),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.655171629288527,
    );
    await testFitBounds(
      rotation: -120,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const LatLng(6.203051199630898, 26.963506247001245),
        const LatLng(-3.3568369334869494, 36.53746975299872),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.3265772927729405,
    );
    await testFitBounds(
      rotation: -60,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const LatLng(6.203051199630936, 26.963506247001288),
        const LatLng(-3.3568369334869113, 36.53746975299876),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.3265772927729405,
    );
    await testFitBounds(
      rotation: 0,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const LatLng(4.214943000000009, 28.95996090051812),
        const LatLng(-1.3621759999999827, 34.54101509948184),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.655171629288527,
    );
    await testFitBounds(
      rotation: 60,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const LatLng(6.203051199630923, 26.96350624700126),
        const LatLng(-3.3568369334869113, 36.5374697529987),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.32657729277294,
    );
    await testFitBounds(
      rotation: 120,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const LatLng(6.203051199630923, 26.96350624700128),
        const LatLng(-3.3568369334869494, 36.53746975299876),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.32657729277294,
    );
    await testFitBounds(
      rotation: 180,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const LatLng(4.214943000000009, 28.95996090051816),
        const LatLng(-1.3621759999999827, 34.54101509948188),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.655171629288527,
    );
    await testFitBounds(
      rotation: 240,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const LatLng(6.203051199630898, 26.963506247001295),
        const LatLng(-3.3568369334869494, 36.537469752998746),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.75048799999998),
      expectedZoom: 5.3265772927729325,
    );
    await testFitBounds(
      rotation: 300,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const LatLng(6.203051199630898, 26.963506247001252),
        const LatLng(-3.3568369334869494, 36.5374697529987),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.32657729277294,
    );
    await testFitBounds(
      rotation: 360,
      cameraConstraint: CameraFit.bounds(bounds: bounds),
      expectedBounds: LatLngBounds(
        const LatLng(4.214943000000034, 28.95996090051815),
        const LatLng(-1.3621759999999827, 34.54101509948189),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
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
        const LatLng(4.594344848163665, 28.579434477861536),
        const LatLng(-1.7425620627594778, 34.92154152213851),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.470747058151099,
    );
    await testFitBounds(
      rotation: -300,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(6.851586477093488, 26.310736007955974),
        const LatLng(-4.008255814512638, 37.190239992043985),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.75048799999998),
      expectedZoom: 5.142152721635503,
    );
    await testFitBounds(
      rotation: -240,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(6.851586477093449, 26.310736007956017),
        const LatLng(-4.008255814512676, 37.19023999204403),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.142152721635507,
    );
    await testFitBounds(
      rotation: -180,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.594344848163639, 28.579434477861508),
        const LatLng(-1.7425620627594396, 34.92154152213845),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999994),
      expectedZoom: 5.470747058151096,
    );
    await testFitBounds(
      rotation: -120,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(6.851586477093488, 26.310736007955988),
        const LatLng(-4.008255814512714, 37.190239992044056),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.142152721635505,
    );
    await testFitBounds(
      rotation: -60,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(6.851586477093424, 26.310736007956045),
        const LatLng(-4.008255814512676, 37.190239992044),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.142152721635509,
    );
    await testFitBounds(
      rotation: 0,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.5943448481636775, 28.579434477861483),
        const LatLng(-1.7425620627594778, 34.921541522138476),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.470747058151097,
    );
    await testFitBounds(
      rotation: 60,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(6.851586477093526, 26.31073600795595),
        const LatLng(-4.008255814512676, 37.19023999204401),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.1421527216355045,
    );
    await testFitBounds(
      rotation: 120,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(6.851586477093526, 26.31073600795599),
        const LatLng(-4.008255814512676, 37.190239992044056),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.142152721635509,
    );
    await testFitBounds(
      rotation: 180,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.594344848163665, 28.579434477861493),
        const LatLng(-1.7425620627594778, 34.92154152213846),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999994),
      expectedZoom: 5.470747058151096,
    );
    await testFitBounds(
      rotation: 240,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(6.851586477093474, 26.31073600795601),
        const LatLng(-4.008255814512676, 37.190239992044035),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.1421527216355045,
    );
    await testFitBounds(
      rotation: 300,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(6.8515864770935, 26.310736007955967),
        const LatLng(-4.008255814512676, 37.19023999204399),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.142152721635513,
    );
    await testFitBounds(
      rotation: 360,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: symmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.594344848163639, 28.579434477861504),
        const LatLng(-1.7425620627594778, 34.921541522138455),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.75048799999998),
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
        const LatLng(4.6220982369962895, 28.551591081081764),
        const LatLng(-2.178518876647162, 35.357754738354586),
      ),
      expectedCenter: const LatLng(1.2239447514276816, 31.954672909718134),
      expectedZoom: 5.368867444131886,
    );
    await testFitBounds(
      rotation: -300,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(7.339702157719629, 26.26297233192825),
        const LatLng(-4.3116309679834535, 37.938537583144694),
      ),
      expectedCenter: const LatLng(1.5218975140385778, 32.10075495753647),
      expectedZoom: 5.040273107616291,
    );
    await testFitBounds(
      rotation: -240,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(7.593940838753139, 26.00655912279901),
        const LatLng(-4.055901266362348, 37.68212437401539),
      ),
      expectedCenter: const LatLng(1.7782041854790855, 31.844341748407157),
      expectedZoom: 5.0402731076162945,
    );
    await testFitBounds(
      rotation: -180,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(5.029019694598646, 28.143221261645415),
        const LatLng(-1.7703923765469525, 34.94938491891824),
      ),
      expectedCenter: const LatLng(1.63218686735705, 31.546303090281786),
      expectedZoom: 5.3688674441318875,
    );
    await testFitBounds(
      rotation: -120,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(7.153494070230884, 25.562438416855343),
        const LatLng(-4.498783850501806, 37.23800366807179),
      ),
      expectedCenter: const LatLng(1.334248403356733, 31.400221042463446),
      expectedZoom: 5.040273107616298,
    );
    await testFitBounds(
      rotation: -60,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(6.899006685396689, 25.81885162598461),
        const LatLng(-4.7543613421791635, 37.49441687720098),
      ),
      expectedCenter: const LatLng(1.0778922142686074, 31.656634251592763),
      expectedZoom: 5.0402731076162945,
    );
    await testFitBounds(
      rotation: 0,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.622098236996252, 28.551591081081764),
        const LatLng(-2.1785188766472, 35.357754738354586),
      ),
      expectedCenter: const LatLng(1.223944751427669, 31.954672909718177),
      expectedZoom: 5.3688674441318875,
    );
    await testFitBounds(
      rotation: 60,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(7.339702157719629, 26.26297233192825),
        const LatLng(-4.3116309679834535, 37.938537583144694),
      ),
      expectedCenter: const LatLng(1.521897514038616, 32.10075495753647),
      expectedZoom: 5.040273107616298,
    );
    await testFitBounds(
      rotation: 120,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(7.593940838753139, 26.00655912279901),
        const LatLng(-4.055901266362348, 37.68212437401539),
      ),
      expectedCenter: const LatLng(1.7782041854790855, 31.8443417484072),
      expectedZoom: 5.0402731076162945,
    );
    await testFitBounds(
      rotation: 180,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(5.029019694598646, 28.143221261645415),
        const LatLng(-1.7703923765469525, 34.94938491891824),
      ),
      expectedCenter: const LatLng(1.63218686735705, 31.546303090281786),
      expectedZoom: 5.3688674441318875,
    );
    await testFitBounds(
      rotation: 240,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(7.153494070230908, 25.562438416855365),
        const LatLng(-4.498783850501768, 37.23800366807177),
      ),
      expectedCenter: const LatLng(1.334248403356733, 31.40022104246349),
      expectedZoom: 5.040273107616298,
    );
    await testFitBounds(
      rotation: 300,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(6.8990066853967145, 25.818851625984607),
        const LatLng(-4.75436134217924, 37.494416877201076),
      ),
      expectedCenter: const LatLng(1.0778922142686453, 31.6566342515928),
      expectedZoom: 5.040273107616299,
    );
    await testFitBounds(
      rotation: 360,
      cameraConstraint: CameraFit.bounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.622098236996252, 28.55159108108176),
        const LatLng(-2.1785188766472, 35.35775473835459),
      ),
      expectedCenter: const LatLng(1.2239447514276816, 31.954672909718134),
      expectedZoom: 5.368867444131886,
    );
  });

  testWidgets('test fit coordinates methods', (tester) async {
    final controller = MapController();
    const coordinates = [
      LatLng(4.214943, 33.925781),
      LatLng(3.480523, 30.844116),
      LatLng(-1.362176, 29.575195),
      LatLng(-0.999705, 33.925781),
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
        controller.camera.center.latitude,
        moreOrLessEquals(expectedCenter.latitude),
      );
      expect(
        controller.camera.center.longitude,
        moreOrLessEquals(expectedCenter.longitude),
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
      expectedCenter: const LatLng(1.0175550985081283, 32.16110216543986),
      expectedZoom: 5.323677289246632,
    );
    await testFitCoordinates(
      rotation: 90,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.655171629288528,
    );
    await testFitCoordinates(
      rotation: 135,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const LatLng(1.0175550985081538, 32.16110216543989),
      expectedZoom: 5.323677289246641,
    );
    await testFitCoordinates(
      rotation: 180,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.655171629288529,
    );
    await testFitCoordinates(
      rotation: 225,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const LatLng(1.0175550985080901, 32.16110216543997),
      expectedZoom: 5.323677289246641,
    );
    await testFitCoordinates(
      rotation: 270,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.655171629288529,
    );
    await testFitCoordinates(
      rotation: 315,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const LatLng(1.0175550985081538, 32.16110216543989),
      expectedZoom: 5.323677289246641,
    );
    await testFitCoordinates(
      rotation: 360,
      fitCoordinates: fitCoordinates(),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.655171629288529,
    );

    // Tests with symmetric padding

    const equalPadding = EdgeInsets.all(12);

    await testFitCoordinates(
      rotation: 45,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const LatLng(1.0175550985081538, 32.16110216543986),
      expectedZoom: 5.139252718109209,
    );
    await testFitCoordinates(
      rotation: 90,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.470747058151099,
    );
    await testFitCoordinates(
      rotation: 135,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const LatLng(1.0175550985081538, 32.161102165439935),
      expectedZoom: 5.139252718109208,
    );
    await testFitCoordinates(
      rotation: 180,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.470747058151097,
    );
    await testFitCoordinates(
      rotation: 225,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const LatLng(1.0175550985081157, 32.16110216543997),
      expectedZoom: 5.13925271810921,
    );
    await testFitCoordinates(
      rotation: 270,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.470747058151099,
    );
    await testFitCoordinates(
      rotation: 315,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const LatLng(1.0175550985081538, 32.16110216543986),
      expectedZoom: 5.13925271810921,
    );
    await testFitCoordinates(
      rotation: 360,
      fitCoordinates: fitCoordinates(padding: equalPadding),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 5.470747058151099,
    );

    // Tests with asymmetric padding

    const asymmetricPadding = EdgeInsets.fromLTRB(12, 12, 24, 24);

    await testFitCoordinates(
      rotation: 45,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const LatLng(1.0175550985081665, 32.524454855645835),
      expectedZoom: 5.037373104089995,
    );
    await testFitCoordinates(
      rotation: 90,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const LatLng(1.63218686735705, 31.954672909718134),
      expectedZoom: 5.36886744413189,
    );
    await testFitCoordinates(
      rotation: 135,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const LatLng(1.3808275978186646, 32.16110216543989),
      expectedZoom: 5.037373104089992,
    );
    await testFitCoordinates(
      rotation: 180,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const LatLng(1.63218686735705, 31.546303090281786),
      expectedZoom: 5.3688674441318875,
    );
    await testFitCoordinates(
      rotation: 225,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const LatLng(1.0175550985081283, 31.797749475233953),
      expectedZoom: 5.037373104089987,
    );
    await testFitCoordinates(
      rotation: 270,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const LatLng(1.2239447514276816, 31.546303090281786),
      expectedZoom: 5.368867444131882,
    );
    await testFitCoordinates(
      rotation: 315,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const LatLng(0.6542416853021571, 32.16110216543989),
      expectedZoom: 5.037373104089994,
    );
    await testFitCoordinates(
      rotation: 360,
      fitCoordinates: fitCoordinates(padding: asymmetricPadding),
      expectedCenter: const LatLng(1.223944751427707, 31.954672909718177),
      expectedZoom: 5.368867444131889,
    );
  });

  testWidgets('test fit inside bounds with rotation', (tester) async {
    final controller = MapController();
    final bounds = LatLngBounds(
      const LatLng(4.214943, 33.925781),
      const LatLng(-1.362176, 29.575195),
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
        controller.camera.visibleBounds.northWest.latitude,
        moreOrLessEquals(expectedBounds.northWest.latitude),
      );
      expect(
        controller.camera.visibleBounds.northWest.longitude,
        moreOrLessEquals(expectedBounds.northWest.longitude),
      );
      expect(
        controller.camera.visibleBounds.southEast.latitude,
        moreOrLessEquals(expectedBounds.southEast.latitude),
      );
      expect(
        controller.camera.visibleBounds.southEast.longitude,
        moreOrLessEquals(expectedBounds.southEast.longitude),
      );
      expect(
        controller.camera.center.latitude,
        moreOrLessEquals(expectedCenter.latitude),
      );
      expect(
        controller.camera.center.longitude,
        moreOrLessEquals(expectedCenter.longitude),
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
        const LatLng(3.6004803825078002, 29.572555447605982),
        const LatLng(-0.7477123980812166, 33.92314144760595),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
      expectedZoom: 6.014499548969527,
    );
    await testFitInsideBounds(
      rotation: -300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.6004803825078002, 29.572555447605975),
        const LatLng(-0.7477123980812166, 33.92314144760596),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447606),
      expectedZoom: 6.464483862446023,
    );
    await testFitInsideBounds(
      rotation: -240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.600480382507826, 29.57255544760597),
        const LatLng(-0.7477123980812166, 33.92314144760596),
      ),
      expectedCenter: const LatLng(1.427411699029666, 31.747848447605964),
      expectedZoom: 6.464483862446028,
    );
    await testFitInsideBounds(
      rotation: -180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.6004803825078002, 29.572555447605986),
        const LatLng(-0.7477123980812166, 33.92314144760594),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
      expectedZoom: 6.014499548969527,
    );
    await testFitInsideBounds(
      rotation: -120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.600480382507864, 29.57255544760598),
        const LatLng(-0.7477123980811785, 33.92314144760595),
      ),
      expectedCenter: const LatLng(1.4274116990296914, 31.74784844760592),
      expectedZoom: 6.464483862446023,
    );
    await testFitInsideBounds(
      rotation: -60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.600480382507788, 29.57255544760597),
        const LatLng(-0.7477123980812675, 33.92314144760596),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
      expectedZoom: 6.464483862446028,
    );
    await testFitInsideBounds(
      rotation: 0,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.6011424536386762, 29.57519499999999),
        const LatLng(-0.7470490737671794, 33.92578099999997),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 6.014499548969527,
    );
    await testFitInsideBounds(
      rotation: 60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.600480382507788, 29.57255544760599),
        const LatLng(-0.7477123980812166, 33.92314144760594),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447606),
      expectedZoom: 6.464483862446023,
    );
    await testFitInsideBounds(
      rotation: 120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.600480382507826, 29.572555447605968),
        const LatLng(-0.7477123980812166, 33.923141447605964),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
      expectedZoom: 6.464483862446028,
    );
    await testFitInsideBounds(
      rotation: 180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.6004803825078002, 29.572555447605982),
        const LatLng(-0.7477123980812166, 33.92314144760595),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
      expectedZoom: 6.014499548969527,
    );
    await testFitInsideBounds(
      rotation: 240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.600480382507788, 29.57255544760601),
        const LatLng(-0.7477123980812675, 33.923141447605985),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.74784844760592),
      expectedZoom: 6.464483862446023,
    );
    await testFitInsideBounds(
      rotation: 300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.600480382507826, 29.572555447606007),
        const LatLng(-0.7477123980812166, 33.92314144760599),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
      expectedZoom: 6.464483862446028,
    );
    await testFitInsideBounds(
      rotation: 360,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.6004803825078002, 29.572555447605986),
        const LatLng(-0.7477123980812166, 33.92314144760594),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
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
        const LatLng(3.8964763198459385, 29.275924583969623),
        const LatLng(-1.0443066595707355, 34.21977231124231),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
      expectedZoom: 5.8300749778321,
    );
    await testFitInsideBounds(
      rotation: -300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.8964763198459766, 29.27592458396959),
        const LatLng(-1.0443066595707737, 34.21977231124234),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
      expectedZoom: 6.280059291308596,
    );
    await testFitInsideBounds(
      rotation: -240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.896476319845951, 29.275924583969623),
        const LatLng(-1.0443066595707355, 34.2197723112423),
      ),
      expectedCenter: const LatLng(1.427411699029666, 31.747848447605964),
      expectedZoom: 6.280059291308594,
    );
    await testFitInsideBounds(
      rotation: -180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.896476319845951, 29.275924583969584),
        const LatLng(-1.0443066595707355, 34.21977231124226),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
      expectedZoom: 5.830074977832107,
    );
    await testFitInsideBounds(
      rotation: -120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.896476319845989, 29.27592458396962),
        const LatLng(-1.0443066595706973, 34.21977231124231),
      ),
      expectedCenter: const LatLng(1.427411699029615, 31.74784844760592),
      expectedZoom: 6.280059291308602,
    );
    await testFitInsideBounds(
      rotation: -60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.896476319845951, 29.275924583969655),
        const LatLng(-1.0443066595707355, 34.219772311242345),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447606),
      expectedZoom: 6.280059291308601,
    );
    await testFitInsideBounds(
      rotation: 0,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.897138166905541, 29.27856413636368),
        const LatLng(-1.0436433889368917, 34.22241186363637),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.750488000000022),
      expectedZoom: 5.830074977832103,
    );
    await testFitInsideBounds(
      rotation: 60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.8964763198459385, 29.27592458396965),
        const LatLng(-1.0443066595707737, 34.21977231124235),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
      expectedZoom: 6.280059291308584,
    );
    await testFitInsideBounds(
      rotation: 120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.896476319845989, 29.27592458396957),
        const LatLng(-1.0443066595706973, 34.219772311242274),
      ),
      expectedCenter: const LatLng(1.427411699029615, 31.74784844760592),
      expectedZoom: 6.280059291308604,
    );
    await testFitInsideBounds(
      rotation: 180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.8964763198459385, 29.275924583969616),
        const LatLng(-1.0443066595707737, 34.21977231124231),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
      expectedZoom: 5.830074977832095,
    );
    await testFitInsideBounds(
      rotation: 240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.8964763198459385, 29.275924583969612),
        const LatLng(-1.0443066595707737, 34.219772311242316),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
      expectedZoom: 6.280059291308607,
    );
    await testFitInsideBounds(
      rotation: 300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.896476319845951, 29.275924583969662),
        const LatLng(-1.0443066595707355, 34.21977231124234),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
      expectedZoom: 6.280059291308594,
    );
    await testFitInsideBounds(
      rotation: 360,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.896476319845951, 29.275924583969612),
        const LatLng(-1.0443066595707737, 34.219772311242316),
      ),
      expectedCenter: const LatLng(1.4274116990296404, 31.747848447605964),
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
        const LatLng(3.9181305666757082, 29.254219886630374),
        const LatLng(-1.3842700558232428, 34.559812569557124),
      ),
      expectedCenter: const LatLng(1.2682880092901039, 31.90701622809379),
      expectedZoom: 5.728195363812894,
    );
    await testFitInsideBounds(
      rotation: -300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.119450877729545, 29.254219886630395),
        const LatLng(-1.182504128069353, 34.55981256955719),
      ),
      expectedCenter: const LatLng(1.4700469435297785, 31.90701622809379),
      expectedZoom: 6.178179677289382,
    );
    await testFitInsideBounds(
      rotation: -240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.235660179641233, 29.137700984385326),
        const LatLng(-1.066007676333678, 34.44329366731215),
      ),
      expectedCenter: const LatLng(1.5865243776059719, 31.790497325848776),
      expectedZoom: 6.178179677289386,
    );
    await testFitInsideBounds(
      rotation: -180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.235660179641169, 28.935884325654747),
        const LatLng(-1.0660076763337163, 34.24147700858153),
      ),
      expectedCenter: const LatLng(1.5865243776059845, 31.58868066711818),
      expectedZoom: 5.728195363812884,
    );
    await testFitInsideBounds(
      rotation: -120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.03436897381288, 28.93588432565474),
        const LatLng(-1.267782377352552, 34.24147700858154),
      ),
      expectedCenter: const LatLng(1.3847756639611237, 31.58868066711814),
      expectedZoom: 6.17817967728938,
    );
    await testFitInsideBounds(
      rotation: -60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.918130566675683, 29.052403227899802),
        const LatLng(-1.384270055823281, 34.35799591082658),
      ),
      expectedCenter: const LatLng(1.2682880092901039, 31.70519956936319),
      expectedZoom: 6.1781796772893856,
    );
    await testFitInsideBounds(
      rotation: 0,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.918792396649435, 29.256859439024414),
        const LatLng(-1.3836068685805785, 34.562452121951196),
      ),
      expectedCenter: const LatLng(1.2689512274367805, 31.909655780487807),
      expectedZoom: 5.728195363812883,
    );
    await testFitInsideBounds(
      rotation: 60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.11945087772957, 29.25421988663039),
        const LatLng(-1.182504128069302, 34.55981256955719),
      ),
      expectedCenter: const LatLng(1.4700469435298167, 31.90701622809375),
      expectedZoom: 6.178179677289379,
    );
    await testFitInsideBounds(
      rotation: 120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.235660179641195, 29.137700984385347),
        const LatLng(-1.066007676333678, 34.443293667312126),
      ),
      expectedCenter: const LatLng(1.5865243776060227, 31.790497325848737),
      expectedZoom: 6.178179677289384,
    );
    await testFitInsideBounds(
      rotation: 180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.235660179641169, 28.935884325654747),
        const LatLng(-1.0660076763337163, 34.24147700858153),
      ),
      expectedCenter: const LatLng(1.5865243776059845, 31.58868066711818),
      expectedZoom: 5.728195363812894,
    );
    await testFitInsideBounds(
      rotation: 240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.03436897381288, 28.93588432565474),
        const LatLng(-1.267782377352552, 34.24147700858154),
      ),
      expectedCenter: const LatLng(1.3847756639610982, 31.58868066711814),
      expectedZoom: 6.178179677289382,
    );
    await testFitInsideBounds(
      rotation: 300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.918130566675683, 29.052403227899802),
        const LatLng(-1.384270055823281, 34.35799591082658),
      ),
      expectedCenter: const LatLng(1.2682880092901676, 31.705199569363227),
      expectedZoom: 6.178179677289388,
    );
    await testFitInsideBounds(
      rotation: 360,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.918130566675721, 29.254219886630356),
        const LatLng(-1.384270055823281, 34.55981256955714),
      ),
      expectedCenter: const LatLng(1.2682880092901039, 31.90701622809375),
      expectedZoom: 5.728195363812886,
    );
  });
}
