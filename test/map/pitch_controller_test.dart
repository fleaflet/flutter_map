import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MapController controller;
  late List<MapEvent> events;

  Future<void> pump(WidgetTester tester, {double initialPitch = 0}) async {
    controller = MapController();
    events = [];
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 400,
        height: 300,
        child: FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialPitch: initialPitch,
            maxPitch: 60,
            initialZoom: 12,
            onMapEvent: events.add,
          ),
          children: const [],
        ),
      ),
    ));
  }

  testWidgets('pitch change', (tester) async {
    await pump(tester);
    final center = controller.camera.center;
    expect(controller.pitch(40, id: 'p'), isTrue);
    expect(controller.camera.pitch, 40);
    expect(controller.camera.zoom, 12);
    expect(controller.camera.center, center);
    final pitchEvents = events.whereType<MapEventPitch>().toList();
    expect(pitchEvents, hasLength(1));
    expect(pitchEvents.single.id, 'p');
    expect(pitchEvents.single.source, MapEventSource.mapController);
    expect(pitchEvents.single.oldCamera.pitch, 0);
    expect(pitchEvents.single.camera.pitch, 40);
  });

  testWidgets('unchanged pitch', (tester) async {
    await pump(tester, initialPitch: 40);
    events.clear();
    expect(controller.pitch(40), isFalse);
    expect(events, isEmpty);
  });

  testWidgets('pitch above the maximum', (tester) async {
    await pump(tester);
    expect(controller.pitch(75), isTrue);
    expect(controller.camera.pitch, 60);
    events.clear();
    expect(controller.pitch(70), isFalse);
    expect(events, isEmpty);
  });
}
