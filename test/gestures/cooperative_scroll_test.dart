import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

Future<MapController> mountMap(WidgetTester tester, ScrollController scroll,
    {required int flags}) async {
  final controller = MapController();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        controller: scroll,
        child: Column(children: [
          SizedBox(
            height: 500,
            child: FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: const LatLng(0, 0),
                initialZoom: 14,
                interactionOptions: InteractionOptions(flags: flags),
              ),
              children: const [],
            ),
          ),
          const SizedBox(height: 1800),
        ]),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return controller;
}

const cooperativeFlags = InteractiveFlag.all &
    ~(InteractiveFlag.drag | InteractiveFlag.flingAnimation);

void main() {
  for (final firstDelta in [20.0, 90.0]) {
    testWidgets('single touch with first delta $firstDelta yields to parent',
        (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final controller =
          await mountMap(tester, scroll, flags: cooperativeFlags);
      final center = controller.camera.center;
      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(FlutterMap)));
      await gesture.moveBy(Offset(0, -firstDelta));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -140));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(100));
      expect(controller.camera.center, center);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('cooperative map retains pinch zoom', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final controller = await mountMap(tester, scroll, flags: cooperativeFlags);
    final zoom = controller.camera.zoom;
    final origin = tester.getCenter(find.byType(FlutterMap));
    final first =
        await tester.startGesture(origin - const Offset(30, 0), pointer: 1);
    final second =
        await tester.startGesture(origin + const Offset(30, 0), pointer: 2);
    await first.moveBy(const Offset(-40, 0));
    await second.moveBy(const Offset(40, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, greaterThan(zoom));
    expect(scroll.offset, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('default map retains fast single pointer dragging',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final controller =
        await mountMap(tester, scroll, flags: InteractiveFlag.all);
    final center = controller.camera.center;
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(FlutterMap)));
    await gesture.moveBy(const Offset(0, -90));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.camera.center, isNot(center));
    expect(scroll.offset, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cooperative map retains double tap hold zoom', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final controller = await mountMap(tester, scroll, flags: cooperativeFlags);
    final zoom = controller.camera.zoom;
    final map = find.byType(FlutterMap);
    await tester.tap(map);
    await tester.pump(const Duration(milliseconds: 100));
    final gesture = await tester.startGesture(tester.getCenter(map));
    await gesture.moveBy(const Offset(0, -90));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, isNot(zoom));
    expect(scroll.offset, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
