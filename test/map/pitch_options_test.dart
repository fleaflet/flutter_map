import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

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

  test('pitch options outside the range from 0 to the limit are rejected', () {
    const aboveLimit = MapOptions.pitchLimit + 1;
    expect(() => MapOptions(maxPitch: aboveLimit), throwsAssertionError);
    expect(() => MapOptions(maxPitch: -1), throwsAssertionError);
    expect(() => MapOptions(initialPitch: aboveLimit), throwsAssertionError);
    expect(() => MapOptions(initialPitch: -1), throwsAssertionError);
  });

  testWidgets('maximum pitch above 60', (tester) async {
    final controller =
        await _pump(tester, const MapOptions(initialPitch: 75, maxPitch: 75));
    expect(controller.camera.pitch, 75);
  });

  test('a camera pitch of 90 degrees or more is rejected', () {
    MapCamera camera(double pitch) => MapCamera(
          crs: const Epsg3857(),
          center: const LatLng(0, 0),
          zoom: 10,
          rotation: 0,
          nonRotatedSize: const Size(400, 300),
          pitch: pitch,
        );
    expect(camera(89).pitch, 89);
    expect(() => camera(90), throwsAssertionError);
    expect(() => camera(-1), throwsAssertionError);
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
