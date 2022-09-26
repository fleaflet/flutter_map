import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets('test fit bounds methods', (tester) async {
    final controller = MapController();
    final bounds = LatLngBounds(
      LatLng(51, 0),
      LatLng(52, 1),
    );
    final expectedCenter = LatLng(51.50274289405741, 0.49999999999999833);

    await tester.pumpWidget(TestApp(controller: controller));

    {
      const fitOptions = FitBoundsOptions();

      final expectedBounds = LatLngBounds(
        LatLng(51.00145915187144, -0.3079873797085076),
        LatLng(52.001427481787005, 1.298485398623206),
      );
      const expectedZoom = 7.451812751543818;

      final fit = controller.centerZoomFitBounds(bounds, options: fitOptions);
      controller.move(fit.center, fit.zoom);
      await tester.pump();
      expect(controller.bounds, equals(expectedBounds));
      expect(controller.center, equals(expectedCenter));
      expect(controller.zoom, equals(expectedZoom));

      controller.fitBounds(bounds, options: fitOptions);
      await tester.pump();
      expect(controller.bounds, equals(expectedBounds));
      expect(controller.center, equals(expectedCenter));
      expect(controller.zoom, equals(expectedZoom));
    }

    {
      const fitOptions = FitBoundsOptions(
        forceIntegerZoomLevel: true,
      );

      final expectedBounds = LatLngBounds(
        LatLng(50.819818262156545, -0.6042480468750001),
        LatLng(52.1874047455997, 1.5930175781250002),
      );
      const expectedZoom = 7;

      final fit = controller.centerZoomFitBounds(bounds, options: fitOptions);
      controller.move(fit.center, fit.zoom);
      await tester.pump();
      expect(controller.bounds, equals(expectedBounds));
      expect(controller.center, equals(expectedCenter));
      expect(controller.zoom, equals(expectedZoom));

      controller.fitBounds(bounds, options: fitOptions);
      await tester.pump();
      expect(controller.bounds, equals(expectedBounds));
      expect(controller.center, equals(expectedCenter));
      expect(controller.zoom, equals(expectedZoom));
    }

    {
      const fitOptions = FitBoundsOptions(
        inside: true,
      );

      final expectedBounds = LatLngBounds(
        LatLng(51.19148727133182, -6.195044477408375e-13),
        LatLng(51.8139520195805, 0.999999999999397),
      );
      const expectedZoom = 8.135709286104404;

      final fit = controller.centerZoomFitBounds(bounds, options: fitOptions);
      controller.move(fit.center, fit.zoom);
      await tester.pump();

      expect(controller.bounds, equals(expectedBounds));
      expect(controller.center, equals(expectedCenter));
      expect(controller.zoom, equals(expectedZoom));

      controller.fitBounds(bounds, options: fitOptions);
      await tester.pump();
      expect(controller.bounds, equals(expectedBounds));
      expect(controller.center, equals(expectedCenter));
      expect(controller.zoom, equals(expectedZoom));
    }

    {
      const fitOptions = FitBoundsOptions(
        inside: true,
        forceIntegerZoomLevel: true,
      );

      final expectedBounds = LatLngBounds(
        LatLng(51.33232774035881, 0.22521972656250003),
        LatLng(51.67425842259517, 0.7745361328125),
      );
      const expectedZoom = 9;

      final fit = controller.centerZoomFitBounds(bounds, options: fitOptions);
      controller.move(fit.center, fit.zoom);
      await tester.pump();
      expect(controller.bounds, equals(expectedBounds));
      expect(controller.center, equals(expectedCenter));
      expect(controller.zoom, equals(expectedZoom));

      controller.fitBounds(bounds, options: fitOptions);
      await tester.pump();
      expect(controller.bounds, equals(expectedBounds));
      expect(controller.center, equals(expectedCenter));
      expect(controller.zoom, equals(expectedZoom));
    }
  });
}

class TestApp extends StatelessWidget {
  final MapController controller;

  const TestApp({
    required this.controller,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          // ensure that map is always of the same size
          child: SizedBox(
            width: 200,
            height: 200,
            child: FlutterMap(
              mapController: controller,
              options: MapOptions(),
            ),
          ),
        ),
      ),
    );
  }
}
