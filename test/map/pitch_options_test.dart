import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

Future<MapController> _pump(WidgetTester tester, MapOptions options) async {
  final controller = MapController();
  await tester.pumpWidget(MaterialApp(
    home: SizedBox(
      width: 400,
      height: 300,
      child: FlutterMap(
        mapController: controller,
        options: options,
        children: const [],
      ),
    ),
  ));
  return controller;
}

void main() {
  testWidgets('default maximum pitch keeps the map unpitched', (tester) async {
    final controller = await _pump(tester, const MapOptions(initialPitch: 30));
    expect(controller.camera.pitch, 0);
  });

  testWidgets('initial pitch is limited to the maximum pitch', (tester) async {
    final controller =
        await _pump(tester, const MapOptions(initialPitch: 50, maxPitch: 45));
    expect(controller.camera.pitch, 45);
  });

  testWidgets('maximum pitch above 60', (tester) async {
    final controller =
        await _pump(tester, const MapOptions(initialPitch: 75, maxPitch: 75));
    expect(controller.camera.pitch, 75);
  });

  testWidgets('maximum pitch above the limit takes effect as the limit',
      (tester) async {
    final controller =
        await _pump(tester, const MapOptions(initialPitch: 90, maxPitch: 90));
    expect(controller.camera.pitch, 85);
  });

  testWidgets('negative initial pitch is limited to 0', (tester) async {
    final controller =
        await _pump(tester, const MapOptions(initialPitch: -10, maxPitch: 45));
    expect(controller.camera.pitch, 0);
  });

  testWidgets('lowering the maximum pitch limits the pitch', (tester) async {
    final controller = MapController();
    Widget map(double maxPitch) => MaterialApp(
          home: SizedBox(
            width: 400,
            height: 300,
            child: FlutterMap(
              mapController: controller,
              options: MapOptions(initialPitch: 40, maxPitch: maxPitch),
              children: const [],
            ),
          ),
        );
    await tester.pumpWidget(map(60));
    expect(controller.camera.pitch, 40);
    await tester.pumpWidget(map(20));
    expect(controller.camera.pitch, 20);
  });
}
