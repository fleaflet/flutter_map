import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

Future<MapController> _pump(
  WidgetTester tester, {
  double pitch = 0,
  double maxPitch = 60,
  InteractionOptions interactionOptions = const InteractionOptions(),
  List<MapEvent>? events,
}) async {
  final controller = MapController();
  await tester.pumpWidget(MaterialApp(
    home: FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: const LatLng(45.5, -122.6),
        initialZoom: 12,
        initialPitch: pitch,
        maxPitch: maxPitch,
        interactionOptions: interactionOptions,
        onMapEvent: events?.add,
      ),
      children: const [],
    ),
  ));
  events?.clear();
  return controller;
}

/// Moves fingers that start at [starts] by [movement] in [steps] equal steps,
/// one finger after the other in each step, and doesn't lift them.
Future<List<TestGesture>> _moveFingers(
  WidgetTester tester,
  List<Offset> starts,
  Offset movement, {
  int steps = 10,
}) async {
  final fingers = [
    for (final (i, start) in starts.indexed)
      await tester.startGesture(start, pointer: i + 1),
  ];
  for (int step = 1; step <= steps; step++) {
    for (final (i, finger) in fingers.indexed) {
      await finger.moveTo(starts[i] + movement * (step / steps));
    }
    await tester.pump(const Duration(milliseconds: 16));
  }
  return fingers;
}

Future<void> _lift(WidgetTester tester, List<TestGesture> fingers) async {
  for (final finger in fingers) {
    await finger.up();
  }
  await tester.pumpAndSettle();
}

const _sideBySide = [Offset(300, 400), Offset(500, 400)];

void main() {
  group('InteractiveFlag.pitch', () {
    test('is a new flag in all', () {
      expect(InteractiveFlag.pitch, 1 << 8);
      expect(InteractiveFlag.hasPitch(InteractiveFlag.all), isTrue);
      expect(
        InteractiveFlag.hasPitch(InteractiveFlag.all & ~InteractiveFlag.pitch),
        isFalse,
      );
    });

    test('is a multi-finger flag', () {
      expect(InteractiveFlag.hasMultiFinger(InteractiveFlag.pitch), isTrue);
    });
  });

  group('InteractionOptions.pitchThreshold', () {
    test('defaults to 2', () {
      expect(const InteractionOptions().pitchThreshold, 2);
    });

    test('is part of equality', () {
      const a = InteractionOptions(pitchThreshold: 10);
      const b = InteractionOptions(pitchThreshold: 10);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const InteractionOptions()));
    });
  });

  group('two-finger pitch gesture', () {
    testWidgets('pitch up', (tester) async {
      final controller = await _pump(tester, pitch: 10);
      final initial = controller.camera;
      final fingers =
          await _moveFingers(tester, _sideBySide, const Offset(0, -40));
      final camera = controller.camera;
      expect(camera.pitch, closeTo(30, 1e-9));
      expect(camera.zoom, initial.zoom);
      expect(camera.rotation, initial.rotation);
      expect(camera.center, initial.center);
      await _lift(tester, fingers);
    });

    testWidgets('pitch limited to the maximum', (tester) async {
      final controller = await _pump(tester, pitch: 40, maxPitch: 45);
      final fingers =
          await _moveFingers(tester, _sideBySide, const Offset(0, -100));
      expect(controller.camera.pitch, 45);
      await _lift(tester, fingers);
    });

    testWidgets('pitch down to 0', (tester) async {
      final controller = await _pump(tester, pitch: 20);
      final fingers =
          await _moveFingers(tester, _sideBySide, const Offset(0, 100));
      expect(controller.camera.pitch, 0);
      await _lift(tester, fingers);
    });

    testWidgets('fingers one above the other', (tester) async {
      final controller = await _pump(tester, pitch: 10);
      final initial = controller.camera;
      // The line between the fingers is 60 degrees from horizontal.
      final fingers = await _moveFingers(
        tester,
        const [Offset(350, 313.4), Offset(450, 486.6)],
        const Offset(0, -40),
      );
      expect(controller.camera.pitch, 10);
      expect(controller.camera.center, isNot(initial.center));
      await _lift(tester, fingers);
    });

    testWidgets('three fingers', (tester) async {
      final controller = await _pump(tester, pitch: 10);
      final fingers = await _moveFingers(
        tester,
        const [Offset(300, 400), Offset(400, 400), Offset(500, 400)],
        const Offset(0, -40),
      );
      expect(controller.camera.pitch, 10);
      await _lift(tester, fingers);
    });

    testWidgets('pitch threshold', (tester) async {
      final controller = await _pump(
        tester,
        pitch: 10,
        interactionOptions: const InteractionOptions(pitchThreshold: 20),
      );
      final initial = controller.camera;
      final fingers =
          await _moveFingers(tester, _sideBySide, const Offset(0, -10));
      await _lift(tester, fingers);
      expect(controller.camera, initial);
    });
  });

  group('other two-finger gestures while pitch is enabled', () {
    Future<MapCamera> pinch(
      WidgetTester tester, {
      required double maxPitch,
      required bool race,
    }) async {
      final controller = await _pump(
        tester,
        maxPitch: maxPitch,
        interactionOptions:
            InteractionOptions(enableMultiFingerGestureRace: race),
      );
      // Both fingers move more vertically than horizontally, in opposite
      // directions, so the map rules out the pitch gesture only after both
      // have moved.
      final fingers = [
        await tester.startGesture(const Offset(350, 400), pointer: 1),
        await tester.startGesture(const Offset(450, 400), pointer: 2),
      ];
      for (int step = 1; step <= 10; step++) {
        await fingers[0].moveTo(Offset(350 - step * 4.0, 400 - step * 12.0));
        await tester.pump(const Duration(milliseconds: 16));
        await fingers[1].moveTo(Offset(450 + step * 4.0, 400 + step * 12.0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      final camera = controller.camera;
      await _lift(tester, fingers);
      return camera;
    }

    for (final race in [false, true]) {
      testWidgets('pinch matches the pinch at maximum pitch 0, race $race',
          (tester) async {
        final expected = await pinch(tester, maxPitch: 0, race: race);
        final actual = await pinch(tester, maxPitch: 60, race: race);
        expect((actual.zoom, actual.rotation), isNot((12.0, 0.0)));
        expect(actual.zoom, expected.zoom);
        expect(actual.rotation, expected.rotation);
        expect(actual.center, expected.center);
        expect(actual.pitch, 0);
      });
    }

    testWidgets('spread after a recognized pitch gesture', (tester) async {
      final controller = await _pump(tester, pitch: 10);
      final initial = controller.camera;
      final fingers =
          await _moveFingers(tester, _sideBySide, const Offset(0, -40));
      for (int step = 1; step <= 10; step++) {
        await fingers[0].moveTo(Offset(300 - step * 10.0, 360));
        await fingers[1].moveTo(Offset(500 + step * 10.0, 360));
        await tester.pump(const Duration(milliseconds: 16));
      }
      final camera = controller.camera;
      expect(camera.pitch, closeTo(30, 1e-9));
      expect(camera.zoom, initial.zoom);
      expect(camera.center, initial.center);
      expect(camera.rotation, initial.rotation);
      await _lift(tester, fingers);
    });

    testWidgets('gesture ends before a decision', (tester) async {
      final events = <MapEvent>[];
      final controller = await _pump(tester, pitch: 10, events: events);
      final initial = controller.camera;
      final fingers = [
        for (final (i, start) in _sideBySide.indexed)
          await tester.startGesture(start, pointer: i + 1),
      ];
      await tester.pump(const Duration(milliseconds: 16));
      await _lift(tester, fingers);
      // Advances past the double-tap timeout that the tap starts.
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.camera, initial);
      expect(events.whereType<MapEventWithMove>(), isEmpty);
    });
  });

  group('end of a two-finger pitch gesture', () {
    testWidgets('pitch events', (tester) async {
      final events = <MapEvent>[];
      final controller = await _pump(tester, pitch: 10, events: events);
      final fingers =
          await _moveFingers(tester, _sideBySide, const Offset(0, -40));
      await _lift(tester, fingers);
      expect(controller.camera.pitch, closeTo(30, 1e-9));
      expect(events.first, isA<MapEventPitchStart>());
      expect(events.first.source, MapEventSource.multiFingerGestureStart);
      final pitchEvents = events.sublist(1, events.length - 1);
      expect(pitchEvents, isNotEmpty);
      expect(pitchEvents, everyElement(isA<MapEventPitch>()));
      expect(
        pitchEvents.map((event) => event.source),
        everyElement(MapEventSource.onMultiFinger),
      );
      expect(pitchEvents.last.camera.pitch, closeTo(30, 1e-9));
      expect(events.last, isA<MapEventPitchEnd>());
      expect(events.last.source, MapEventSource.multiFingerEnd);
    });

    testWidgets('no fling after a pitch gesture', (tester) async {
      final controller = await _pump(tester, pitch: 10);
      final initial = controller.camera;
      final fingers = await _moveFingers(
        tester,
        _sideBySide,
        const Offset(0, -200),
        steps: 5,
      );
      final pitched = controller.camera;
      expect(pitched.pitch, greaterThan(10));
      for (final finger in fingers) {
        await finger.up();
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
      expect(controller.camera, pitched);
      expect(controller.camera.center, initial.center);
    });

    testWidgets('removing the pitch flag ends the pitch gesture',
        (tester) async {
      final events = <MapEvent>[];
      final controller = MapController();
      Widget map(int flags) => MaterialApp(
            home: FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: const LatLng(45.5, -122.6),
                initialZoom: 12,
                initialPitch: 10,
                maxPitch: 60,
                interactionOptions: InteractionOptions(flags: flags),
                onMapEvent: events.add,
              ),
              children: const [],
            ),
          );
      await tester.pumpWidget(map(InteractiveFlag.all));
      final fingers =
          await _moveFingers(tester, _sideBySide, const Offset(0, -20));
      expect(controller.camera.pitch, closeTo(20, 1e-9));
      events.clear();
      await tester.pumpWidget(
        map(InteractiveFlag.all & ~InteractiveFlag.pitch),
      );
      expect(events.single, isA<MapEventPitchEnd>());
      expect(events.single.source, MapEventSource.interactiveFlagsChanged);
      for (int step = 1; step <= 10; step++) {
        await fingers[0].moveTo(Offset(300, 380 - step * 2.0));
        await fingers[1].moveTo(Offset(500, 380 - step * 2.0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await _lift(tester, fingers);
      expect(controller.camera.pitch, closeTo(20, 1e-9));
    });
  });

  group('Ctrl-drag pitch', () {
    // The map fills the 800 x 600 test screen, so its center is (400, 300).
    Future<void> ctrlDrag(WidgetTester tester, List<Offset> positions) async {
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

    List<Offset> path(Offset from, Offset to, {int steps = 10}) => [
          for (int i = 0; i <= steps; i++) from + (to - from) * (i / steps),
        ];

    testWidgets('Ctrl-drag up', (tester) async {
      final controller = await _pump(tester, pitch: 10);
      await ctrlDrag(
          tester, path(const Offset(400, 500), const Offset(400, 460)));
      expect(controller.camera.pitch, closeTo(30, 1e-9));
      expect(controller.camera.rotation, 0);
    });

    testWidgets('Ctrl-drag sideways below the center', (tester) async {
      final controller = await _pump(tester, pitch: 10);
      final center = controller.camera.center;
      await ctrlDrag(
          tester, path(const Offset(300, 500), const Offset(500, 500)));
      // Relative to the center, the cursor moves from (-100, 200) to
      // (100, 200), which turns it 53.13 degrees counterclockwise on the
      // screen; the map rotates in the same direction.
      expect(controller.camera.rotation % 360, closeTo(306.87, 0.01));
      expect(controller.camera.pitch, 10);
      expect(controller.camera.center, center);
    });

    testWidgets('Ctrl-drag near the center', (tester) async {
      final controller = await _pump(tester, pitch: 10);
      await ctrlDrag(tester, const [Offset(400, 350), Offset(410, 350)]);
      expect(controller.camera.rotation % 360, closeTo(352, 1e-9));
      expect(controller.camera.pitch, 10);
    });

    testWidgets('set north on click while pitch is enabled', (tester) async {
      final controller = await _pump(tester, pitch: 10);
      await ctrlDrag(tester, const [Offset(600, 300)]);
      expect(controller.camera.rotation, 0);
    });

    testWidgets('Ctrl-drag pitch events', (tester) async {
      final events = <MapEvent>[];
      await _pump(tester, pitch: 10, events: events);
      await ctrlDrag(
          tester, path(const Offset(400, 500), const Offset(400, 460)));
      final gestureEvents = events
          .where((event) => event is! MapEventTap && event is! MapEventMove)
          .toList();
      expect(gestureEvents[0], isA<MapEventRotateStart>());
      expect(gestureEvents[1], isA<MapEventPitchStart>());
      final pitchEvents = gestureEvents.sublist(2, gestureEvents.length - 2);
      expect(pitchEvents, isNotEmpty);
      expect(pitchEvents, everyElement(isA<MapEventPitch>()));
      expect(gestureEvents[gestureEvents.length - 2], isA<MapEventRotateEnd>());
      expect(gestureEvents.last, isA<MapEventPitchEnd>());
      expect(
        gestureEvents.map((event) => event.source),
        everyElement(MapEventSource.cursorKeyboardRotation),
      );
    });
  });

  testWidgets('pitch start and end events', (tester) async {
    final controller = MapController();
    final events = <MapEvent>[];
    await tester.pumpWidget(MaterialApp(
      home: FlutterMap(
        mapController: controller,
        options: MapOptions(onMapEvent: events.add),
        children: const [],
      ),
    ));
    events.clear();
    (controller as MapControllerImpl)
      ..pitchStarted(MapEventSource.multiFingerGestureStart)
      ..pitchEnded(MapEventSource.multiFingerEnd);
    expect(events, hasLength(2));
    expect(events[0], isA<MapEventPitchStart>());
    expect(events[0].source, MapEventSource.multiFingerGestureStart);
    expect(events[1], isA<MapEventPitchEnd>());
    expect(events[1].source, MapEventSource.multiFingerEnd);
  });
}
