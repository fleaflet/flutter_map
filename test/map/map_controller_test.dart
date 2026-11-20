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
        const LatLng(3.601142453638689, 29.57519500000004),
        const LatLng(-0.7470490737671414, 33.92578100000001),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.750488000000022),
      expectedZoom: 6.014499548969527,
    );
    await testFitInsideBounds(
      rotation: -300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.6011424536386762, 29.575194999999994),
        const LatLng(-0.7470490737671794, 33.925780999999965),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 6.464483862446023,
    );
    await testFitInsideBounds(
      rotation: -240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.6011424536387144, 29.57519500000003),
        const LatLng(-0.7470490737671794, 33.925781000000015),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.750488000000022),
      expectedZoom: 6.464483862446028,
    );
    await testFitInsideBounds(
      rotation: -180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.6011424536386762, 29.575194999999987),
        const LatLng(-0.7470490737671794, 33.92578099999997),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 6.014499548969527,
    );
    await testFitInsideBounds(
      rotation: -120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.6011424536387144, 29.57519499999998),
        const LatLng(-0.7470490737671794, 33.92578099999998),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.75048799999998),
      expectedZoom: 6.464483862446023,
    );
    await testFitInsideBounds(
      rotation: -60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.6011424536386762, 29.575195000000033),
        const LatLng(-0.7470490737671794, 33.925781000000015),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.750488000000022),
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
        const LatLng(3.6011424536386762, 29.575195000000004),
        const LatLng(-0.7470490737671414, 33.92578099999996),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.75048799999998),
      expectedZoom: 6.464483862446023,
    );
    await testFitInsideBounds(
      rotation: 120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.6011424536387144, 29.575194999999983),
        const LatLng(-0.7470490737671794, 33.92578099999998),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.75048799999998),
      expectedZoom: 6.464483862446028,
    );
    await testFitInsideBounds(
      rotation: 180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.601142453638689, 29.57519500000004),
        const LatLng(-0.7470490737671414, 33.92578100000001),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.750488000000022),
      expectedZoom: 6.014499548969527,
    );
    await testFitInsideBounds(
      rotation: 240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.6011424536386762, 29.575194999999994),
        const LatLng(-0.7470490737671794, 33.925780999999965),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 6.464483862446023,
    );
    await testFitInsideBounds(
      rotation: 300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.6011424536387144, 29.57519500000003),
        const LatLng(-0.7470490737671794, 33.925781000000015),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.750488000000022),
      expectedZoom: 6.464483862446028,
    );
    await testFitInsideBounds(
      rotation: 360,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.6011424536386762, 29.575194999999987),
        const LatLng(-0.7470490737671794, 33.92578099999997),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
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
        const LatLng(3.8971381669055662, 29.27856413636367),
        const LatLng(-1.0436433889368917, 34.222411863636374),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.750488000000022),
      expectedZoom: 5.8300749778321,
    );
    await testFitInsideBounds(
      rotation: -300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.8971381669055662, 29.278564136363688),
        const LatLng(-1.0436433889368917, 34.22241186363635),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.750488000000022),
      expectedZoom: 6.280059291308596,
    );
    await testFitInsideBounds(
      rotation: -240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.897138166905579, 29.278564136363666),
        const LatLng(-1.0436433889368917, 34.22241186363638),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.750488000000022),
      expectedZoom: 6.280059291308594,
    );
    await testFitInsideBounds(
      rotation: -180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.8971381669055662, 29.27856413636367),
        const LatLng(-1.0436433889368917, 34.222411863636374),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.750488000000022),
      expectedZoom: 5.830074977832107,
    );
    await testFitInsideBounds(
      rotation: -120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.8971381669055662, 29.278564136363663),
        const LatLng(-1.0436433889369299, 34.22241186363638),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.750488000000022),
      expectedZoom: 6.280059291308602,
    );
    await testFitInsideBounds(
      rotation: -60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.8971381669056044, 29.278564136363617),
        const LatLng(-1.0436433889368917, 34.22241186363634),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.75048799999998),
      expectedZoom: 6.280059291308601,
    );
    await testFitInsideBounds(
      rotation: 0,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.8971381669055662, 29.27856413636364),
        const LatLng(-1.0436433889368917, 34.22241186363632),
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
        const LatLng(3.897138166905579, 29.27856413636361),
        const LatLng(-1.0436433889369299, 34.222411863636346),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
      expectedZoom: 6.280059291308584,
    );
    await testFitInsideBounds(
      rotation: 120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.897138166905579, 29.278564136363627),
        const LatLng(-1.0436433889368917, 34.22241186363633),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.75048799999998),
      expectedZoom: 6.280059291308604,
    );
    await testFitInsideBounds(
      rotation: 180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.8971381669055662, 29.27856413636365),
        const LatLng(-1.0436433889368917, 34.22241186363631),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.75048799999998),
      expectedZoom: 5.830074977832095,
    );
    await testFitInsideBounds(
      rotation: 240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.8971381669055156, 29.27856413636364),
        const LatLng(-1.0436433889369299, 34.22241186363632),
      ),
      expectedCenter: const LatLng(1.4280748738291098, 31.75048799999998),
      expectedZoom: 6.280059291308607,
    );
    await testFitInsideBounds(
      rotation: 300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.8971381669056044, 29.278564136363663),
        const LatLng(-1.0436433889368917, 34.22241186363638),
      ),
      expectedCenter: const LatLng(1.4280748738291607, 31.750488000000022),
      expectedZoom: 6.280059291308594,
    );
    await testFitInsideBounds(
      rotation: 360,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: equalPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.897138166905541, 29.27856413636364),
        const LatLng(-1.0436433889368917, 34.22241186363632),
      ),
      expectedCenter: const LatLng(1.4280748738291353, 31.75048799999998),
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
        const LatLng(3.918792396649435, 29.256859439024424),
        const LatLng(-1.3836068685805403, 34.56245212195119),
      ),
      expectedCenter: const LatLng(1.2689512274367805, 31.909655780487807),
      expectedZoom: 5.728195363812894,
    );
    await testFitInsideBounds(
      rotation: -300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.12011254433048, 29.256859439024378),
        const LatLng(-1.1818408885177978, 34.562452121951154),
      ),
      expectedCenter: const LatLng(1.4707101058461178, 31.909655780487768),
      expectedZoom: 6.178179677289382,
    );
    await testFitInsideBounds(
      rotation: -240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.236321748218643, 29.14034053677935),
        const LatLng(-1.065344410325353, 34.44593321970615),
      ),
      expectedCenter: const LatLng(1.58718750394679, 31.793136878242752),
      expectedZoom: 6.178179677289386,
    );
    await testFitInsideBounds(
      rotation: -180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.236321748218655, 28.938523878048816),
        const LatLng(-1.0653444103252767, 34.24411656097558),
      ),
      expectedCenter: const LatLng(1.5871875039468282, 31.5913202195122),
      expectedZoom: 5.728195363812884,
    );
    await testFitInsideBounds(
      rotation: -120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.035030710455137, 28.938523878048795),
        const LatLng(-1.2671191589064073, 34.2441165609756),
      ),
      expectedCenter: const LatLng(1.3854388508768907, 31.5913202195122),
      expectedZoom: 6.17817967728938,
    );
    await testFitInsideBounds(
      rotation: -60,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.91879239664946, 29.055042780293853),
        const LatLng(-1.3836068685805403, 34.36063546322064),
      ),
      expectedCenter: const LatLng(1.2689512274367805, 31.707839121757246),
      expectedZoom: 6.1781796772893856,
    );
    await testFitInsideBounds(
      rotation: 0,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.918792396649435, 29.25685943902441),
        const LatLng(-1.3836068685805785, 34.5624521219512),
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
        const LatLng(4.12011254433048, 29.256859439024378),
        const LatLng(-1.1818408885177978, 34.562452121951154),
      ),
      expectedCenter: const LatLng(1.4707101058461178, 31.909655780487768),
      expectedZoom: 6.178179677289379,
    );
    await testFitInsideBounds(
      rotation: 120,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.236321748218681, 29.140340536779348),
        const LatLng(-1.065344410325315, 34.445933219706156),
      ),
      expectedCenter: const LatLng(1.5871875039468282, 31.793136878242752),
      expectedZoom: 6.178179677289384,
    );
    await testFitInsideBounds(
      rotation: 180,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.236321748218655, 28.938523878048812),
        const LatLng(-1.0653444103252767, 34.244116560975584),
      ),
      expectedCenter: const LatLng(1.5871875039468282, 31.5913202195122),
      expectedZoom: 5.728195363812894,
    );
    await testFitInsideBounds(
      rotation: 240,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(4.0350307104551115, 28.93852387804881),
        const LatLng(-1.267119158906369, 34.244116560975584),
      ),
      expectedCenter: const LatLng(1.3854388508768907, 31.5913202195122),
      expectedZoom: 6.178179677289382,
    );
    await testFitInsideBounds(
      rotation: 300,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.918792396649435, 29.055042780293846),
        const LatLng(-1.3836068685805785, 34.360635463220646),
      ),
      expectedCenter: const LatLng(1.2689512274367551, 31.707839121757246),
      expectedZoom: 6.178179677289388,
    );
    await testFitInsideBounds(
      rotation: 360,
      cameraConstraint: CameraFit.insideBounds(
        bounds: bounds,
        padding: asymmetricPadding,
      ),
      expectedBounds: LatLngBounds(
        const LatLng(3.918792396649435, 29.256859439024424),
        const LatLng(-1.3836068685805403, 34.56245212195119),
      ),
      expectedCenter: const LatLng(1.2689512274367805, 31.909655780487807),
      expectedZoom: 5.728195363812886,
    );
  });
}
