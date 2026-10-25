import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

// Camera positions after a drag, a fling and a pinch, recorded before pitch
// support was added, so that changes to gestures for pitch can be shown to
// leave the unpitched map's gestures unchanged.

Future<MapController> _pump(WidgetTester tester) async {
  final controller = MapController();
  await tester.pumpWidget(MaterialApp(
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 400,
        height: 600,
        child: FlutterMap(
          mapController: controller,
          options: const MapOptions(
            initialCenter: LatLng(45.5, -122.6),
            initialZoom: 12,
            initialRotation: 30,
          ),
          children: const [],
        ),
      ),
    ),
  ));
  return controller;
}

void _expectCenter(MapController controller, (double, double) expected) {
  expect(controller.camera.center.latitude, closeTo(expected.$1, 1e-9));
  expect(controller.camera.center.longitude, closeTo(expected.$2, 1e-9));
}

void main() {
  testWidgets('drag', (tester) async {
    final controller = await _pump(tester);
    final gesture = await tester.startGesture(const Offset(200, 100));
    for (int i = 1; i <= 20; i++) {
      await gesture.moveTo(Offset(200 + i * 3.0, 100 + i * 20.0));
      await tester.pump(const Duration(milliseconds: 100));
    }
    _expectCenter(controller, (45.5760888583345, -122.6865041243764));
    await gesture.up();
    await tester.pumpAndSettle();
    _expectCenter(controller, (45.5760888583345, -122.6865041243764));
  });

  testWidgets('fling', (tester) async {
    final controller = await _pump(tester);
    await tester.flingFrom(const Offset(200, 100), const Offset(60, 400), 1500);
    await tester.pumpAndSettle();
    _expectCenter(controller, (45.648197134706926, -122.76859103266955));
  });

  testWidgets('pinch zoom and move', (tester) async {
    final controller = await _pump(tester);
    final a = await tester.startGesture(const Offset(150, 300), pointer: 1);
    final b = await tester.startGesture(const Offset(250, 300), pointer: 2);
    for (int i = 1; i <= 10; i++) {
      await a.moveTo(Offset(150 - i * 5.0, 300 + i * 10.0));
      await b.moveTo(Offset(250 + i * 5.0, 300 + i * 10.0));
      await tester.pump(const Duration(milliseconds: 100));
    }
    _expectCenter(controller, (45.5087058730637, -122.60766726630374));
    expect(controller.camera.zoom, 13);
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
  });
}
