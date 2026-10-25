import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

Future<MapController> _pump(
  WidgetTester tester, {
  required double pitch,
  double rotation = 30,
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

/// The distance, in projected pixels at the camera zoom, between the
/// coordinate under a focal point near the bottom of the map before a 45
/// degree two-finger rotation and the ground point under it afterwards.
Future<double> _rotationDrift(
  WidgetTester tester,
  double pitch,
  double degreesPerFrame,
) async {
  final controller = await _pump(tester, pitch: pitch, rotation: 0);
  const focal = Offset(200, 520);
  final coordinate = controller.camera.screenOffsetToLatLng(focal);
  final a = await tester.startGesture(focal + const Offset(-60, 0), pointer: 1);
  final b = await tester.startGesture(focal + const Offset(60, 0), pointer: 2);
  final frames = (45 / degreesPerFrame).round();
  for (int i = 1; i <= frames; i++) {
    final angle = i * degreesPerFrame * pi / 180;
    final arm = Offset(cos(angle), sin(angle)) * 60;
    await a.moveTo(focal - arm);
    await b.moveTo(focal + arm);
    await tester.pump(const Duration(milliseconds: 16));
  }
  final camera = controller.camera;
  expect(camera.rotation.abs(), greaterThan(10));
  final drift = (camera.projectAtZoom(coordinate) -
          camera.projectAtZoom(camera.screenOffsetToLatLng(focal)))
      .distance;
  await a.up();
  await b.up();
  await tester.pumpAndSettle();
  return drift;
}

double _distanceOnScreen(
        MapController controller, LatLng coordinate, Offset position) =>
    (controller.camera.latLngToScreenOffset(coordinate) - position).distance;

void main() {
  testWidgets('drag keeps the coordinate under the pointer', (tester) async {
    final controller = await _pump(tester, pitch: 60);
    final gesture = await tester.startGesture(const Offset(200, 40));
    // Past the touch slop, so that the drag has started.
    await gesture.moveTo(const Offset(200, 70));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(const Offset(201, 72));
    await tester.pump(const Duration(milliseconds: 100));
    final coordinate =
        controller.camera.screenOffsetToLatLng(const Offset(201, 72));
    for (int i = 1; i <= 20; i++) {
      await gesture.moveTo(Offset(201 + i * 2.0, 72 + i * 22.0));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      _distanceOnScreen(controller, coordinate, const Offset(241, 512)),
      lessThan(0.5),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('fling continues in the direction of the ground movement',
      (tester) async {
    final controller = await _pump(tester, pitch: 50);
    final initial = controller.camera;
    const start = Offset(150, 100);
    const drag = Offset(40, 300);
    // A straight screen line is a straight ground line, so the ground under
    // the drag moves along the ground shift from its start to its end.
    final dragShift =
        initial.projectAtZoom(initial.screenOffsetToLatLng(start)) -
            initial.projectAtZoom(initial.screenOffsetToLatLng(start + drag));
    await tester.flingFrom(start, drag, 1500);
    await tester.pumpAndSettle();
    final moved = controller.camera.projectAtZoom(controller.camera.center) -
        initial.projectAtZoom(initial.center);
    final cosine = (dragShift.dx * moved.dx + dragShift.dy * moved.dy) /
        (dragShift.distance * moved.distance);
    expect(cosine, greaterThan(0.999));
    expect(moved.distance, greaterThan(dragShift.distance * 1.1));
  });

  testWidgets('scroll-wheel zoom keeps the coordinate under the cursor',
      (tester) async {
    final controller = await _pump(tester, pitch: 50);
    const cursor = Offset(300, 40);
    final coordinate = controller.camera.screenOffsetToLatLng(cursor);
    await tester.sendEventToBinding(
      const PointerScrollEvent(position: cursor, scrollDelta: Offset(0, -100)),
    );
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, greaterThan(12));
    expect(_distanceOnScreen(controller, coordinate, cursor), lessThan(0.5));
  });

  // The unpitched gesture already leaves a drift proportional to the rotation
  // per frame, so pitch is checked to add none.
  for (final degreesPerFrame in [0.75, 3.0]) {
    testWidgets(
        'two-finger rotation at $degreesPerFrame degrees per frame drifts '
        'as much as unpitched', (tester) async {
      final unpitched = await _rotationDrift(tester, 0, degreesPerFrame);
      final pitched = await _rotationDrift(tester, 50, degreesPerFrame);
      expect(pitched, closeTo(unpitched, 0.05));
    });
  }

  testWidgets('flingAnimatedRaw moves along the screen direction',
      (tester) async {
    final controller = await _pump(tester, pitch: 50);
    final initial = controller.camera;
    (controller as MapControllerImpl).flingAnimatedRaw(
      velocity: 1,
      direction: const Offset(0, 1),
      begin: Offset.zero,
      hasGesture: false,
    );
    await tester.pumpAndSettle();
    final screen = initial.latLngToScreenOffset(controller.camera.center);
    expect(screen.dx, closeTo(200, 0.5));
    expect(screen.dy, lessThan(300));
  });
}
