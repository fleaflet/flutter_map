import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

Future<MapController> _pump(
  WidgetTester tester, {
  required double pitch,
  required double rotation,
}) async {
  final controller = MapController();
  await tester.pumpWidget(MaterialApp(
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 400,
        height: 600,
        child: FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: const LatLng(45.5, -122.6),
            initialZoom: 12,
            initialRotation: rotation,
            initialPitch: pitch,
            maxPitch: 60,
          ),
          children: const [],
        ),
      ),
    ),
  ));
  return controller;
}

void main() {
  const target = LatLng(45.52, -122.65);

  for (final pitch in [0.0, 60.0]) {
    testWidgets('move with offset, pitch $pitch', (tester) async {
      final controller = await _pump(tester, pitch: pitch, rotation: 30);
      controller.move(target, 13, offset: const Offset(0, 200));
      final screen = controller.camera.latLngToScreenOffset(target);
      expect((screen - const Offset(200, 500)).distance, lessThan(0.5));
    });
  }

  for (final pitch in [0.0, 45.0]) {
    testWidgets('rotate around a point, pitch $pitch', (tester) async {
      final controller = await _pump(tester, pitch: pitch, rotation: 0);
      const point = Offset(250, 550);
      final coordinate = controller.camera.screenOffsetToLatLng(point);
      controller.rotateAroundPoint(90, offset: point - const Offset(200, 300));
      final screen = controller.camera.latLngToScreenOffset(coordinate);
      expect((screen - point).distance, lessThan(0.5));
    });
  }

  testWidgets('move with offset at pitch 0 is unchanged', (tester) async {
    final controller = await _pump(tester, pitch: 0, rotation: 30);
    final camera = controller.camera;
    const offset = Offset(30, 200);
    final newPoint = camera.projectAtZoom(target, 13);
    final expected = camera.unprojectAtZoom(
      camera.rotatePoint(newPoint, newPoint - offset),
      13,
    );
    controller.move(target, 13, offset: offset);
    expect(controller.camera.center.latitude, closeTo(expected.latitude, 1e-9));
    expect(
        controller.camera.center.longitude, closeTo(expected.longitude, 1e-9));
  });

  testWidgets('offset above the horizon is ignored', (tester) async {
    final controller = await _pump(tester, pitch: 60, rotation: 0);
    controller.move(target, 13, offset: const Offset(0, -5000));
    expect(controller.camera.center.latitude, closeTo(target.latitude, 1e-9));
    expect(controller.camera.center.longitude, closeTo(target.longitude, 1e-9));
  });
}
