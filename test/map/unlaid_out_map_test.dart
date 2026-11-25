import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// Builds [map] on a route that an opaque route covers from the very first
/// frame.
///
/// The `Overlay` builds the covered route but does not lay it out, so the
/// `LayoutBuilder` inside `FlutterMap` does not run and the map's
/// `MapInteractiveViewer` is not created until the route is uncovered.
///
/// This happens whenever an app is launched straight into a deeper screen,
/// for example from a deep link or a notification, with the map underneath.
Widget _coveredMap(Widget map) => MaterialApp(
  // Without `onGenerateRoute`, `MaterialApp` builds no `Navigator` and
  // ignores `onGenerateInitialRoutes`.
  onGenerateRoute: (_) => null,
  onGenerateInitialRoutes: (_) => [
    MaterialPageRoute<void>(builder: (_) => Scaffold(body: map)),
    MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('cover')),
    ),
  ],
);

Future<void> _uncover(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator)).pop();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'onMapReady fires once after the first frame for a map that is laid out '
    'immediately',
    (tester) async {
      var readyCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: FlutterMap(
            options: MapOptions(onMapReady: () => readyCount++),
            children: const [],
          ),
        ),
      );

      expect(readyCount, 1);

      await tester.pump();

      expect(readyCount, 1);
    },
  );

  testWidgets(
    'onMapReady waits until a covered map is laid out, and moving the camera '
    'from it does not throw and is kept',
    (tester) async {
      final controller = MapController();
      addTearDown(controller.dispose);
      const destination = LatLng(52, 9);
      var readyCount = 0;

      await tester.pumpWidget(
        _coveredMap(
          FlutterMap(
            mapController: controller,
            options: MapOptions(
              onMapReady: () {
                readyCount++;
                controller.move(destination, 15);
              },
            ),
            children: const [],
          ),
        ),
      );
      await tester.pump();

      expect(readyCount, 0);

      await _uncover(tester);

      expect(tester.takeException(), isNull);
      expect(readyCount, 1);
      expect(controller.camera.center, destination);
      expect(controller.camera.zoom, 15);
    },
  );

  testWidgets(
    'onMapReady never fires for a covered map that is disposed before it is '
    'laid out',
    (tester) async {
      var readyCount = 0;

      await tester.pumpWidget(
        _coveredMap(
          FlutterMap(
            options: MapOptions(onMapReady: () => readyCount++),
            children: const [],
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(readyCount, 0);
    },
  );
}
