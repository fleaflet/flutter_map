import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

// The cursor/keyboard rotation angle is measured about the center of the
// screen, so the map fills the 800 x 600 test screen.
Future<MapController> _pump(
  WidgetTester tester, {
  CursorKeyboardRotationOptions cursorKeyboardRotationOptions =
      const CursorKeyboardRotationOptions(),
}) async {
  final controller = MapController();
  await tester.pumpWidget(MaterialApp(
    home: FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: const LatLng(45.5, -122.6),
        initialZoom: 12,
        interactionOptions: InteractionOptions(
          cursorKeyboardRotationOptions: cursorKeyboardRotationOptions,
        ),
      ),
      children: const [],
    ),
  ));
  return controller;
}

double _normalized(double degrees) => degrees % 360;

Future<void> _ctrlDrag(WidgetTester tester, List<Offset> positions) async {
  await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
  final gesture = await tester.startGesture(
    positions.first,
    kind: PointerDeviceKind.mouse,
  );
  for (final position in positions.skip(1)) {
    await gesture.moveTo(position);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
  // Advances past the double-tap timeout that a click starts.
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('Ctrl-drag rotates by the change of the cursor angle',
      (tester) async {
    final controller = await _pump(tester);
    final center = controller.camera.center;
    // From below the screen center to the right of it: the angle changes from
    // 180 to 90 degrees.
    await _ctrlDrag(tester, const [
      Offset(400, 500),
      Offset(500, 450),
      Offset(600, 300),
    ]);
    expect(_normalized(controller.camera.rotation), closeTo(270, 1e-9));
    expect(controller.camera.center, center);
    expect(controller.camera.pitch, 0);
  });

  testWidgets('Ctrl-drag with set north rotates to the cursor angle',
      (tester) async {
    final controller = await _pump(
      tester,
      cursorKeyboardRotationOptions: const CursorKeyboardRotationOptions(
        behaviour: CursorRotationBehaviour.setNorth,
      ),
    );
    // The first movement rotates the map by the change of angle (90 - 180),
    // and later movements rotate it to the cursor angle itself, which is 0
    // degrees above the center.
    await _ctrlDrag(tester, const [
      Offset(400, 500),
      Offset(600, 300),
      Offset(400, 100),
    ]);
    expect(_normalized(controller.camera.rotation), closeTo(0, 1e-9));
  });

  testWidgets('Ctrl-click sets north to the clicked angle', (tester) async {
    final controller = await _pump(tester);
    await _ctrlDrag(tester, const [Offset(600, 300)]);
    expect(_normalized(controller.camera.rotation), closeTo(90, 1e-9));
  });

  testWidgets('two-finger vertical drag moves the map', (tester) async {
    final controller = await _pump(tester);
    final initial = controller.camera;
    const focalStart = Offset(400, 400);
    final coordinate = initial.screenOffsetToLatLng(focalStart);
    final a = await tester.startGesture(const Offset(300, 400), pointer: 1);
    final b = await tester.startGesture(const Offset(500, 400), pointer: 2);
    for (int i = 1; i <= 10; i++) {
      await a.moveTo(Offset(300, 400 - i * 20.0));
      await b.moveTo(Offset(500, 400 - i * 20.0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final camera = controller.camera;
    // Each update moves the map so that the coordinate is under the focal
    // point of the previous update; here that is the focal point after finger
    // a's last move, 10 px below the final focal point.
    expect(
      (camera.latLngToScreenOffset(coordinate) - const Offset(400, 210))
          .distance,
      lessThan(0.5),
    );
    expect(camera.zoom, initial.zoom);
    expect(camera.rotation, initial.rotation);
    expect(camera.pitch, 0);
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
  });
}
