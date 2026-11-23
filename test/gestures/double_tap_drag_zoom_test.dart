import 'package:flutter/gestures.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils/test_app.dart';

Future<void> expectHeldZoom(
  WidgetTester tester, {
  required PointerDeviceKind kind,
  required Duration betweenTaps,
  required Duration hold,
}) async {
  final controller = MapController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(TestApp(controller: controller));
  final center = tester.getCenter(find.byType(FlutterMap));
  final zoom = controller.camera.zoom;
  final position = controller.camera.center;
  final first = await tester.startGesture(center, kind: kind);
  await first.up();
  // Advance the gesture clock to the second press, not a background wait.
  await tester.pump(betweenTaps);
  final second = await tester.startGesture(center, kind: kind);
  await tester.pump(hold);
  expect(controller.camera.zoom, zoom, reason: 'holding must not zoom early');
  await second.moveBy(const Offset(0, -20));
  await second.moveBy(const Offset(0, -40));
  await second.moveBy(const Offset(0, -40));
  await tester.pump();
  expect(controller.camera.zoom, isNot(zoom));
  expect(controller.camera.center, position);
  final draggedZoom = controller.camera.zoom;
  await second.up();
  await tester.pumpAndSettle();
  expect(controller.camera.zoom, draggedZoom,
      reason: 'releasing a drag must not also perform double-tap zoom');
}

void main() {
  testWidgets(
      'touch second press survives the long-press deadline',
      (tester) => expectHeldZoom(tester,
          kind: PointerDeviceKind.touch,
          betweenTaps: const Duration(milliseconds: 100),
          hold: const Duration(seconds: 1)));
  testWidgets(
      'mouse second press survives the long-press deadline',
      (tester) => expectHeldZoom(tester,
          kind: PointerDeviceKind.mouse,
          betweenTaps: const Duration(milliseconds: 100),
          hold: const Duration(seconds: 1)));
  testWidgets(
      'touch second press near the inter-tap deadline still zooms',
      (tester) => expectHeldZoom(tester,
          kind: PointerDeviceKind.touch,
          betweenTaps: const Duration(milliseconds: 200),
          hold: const Duration(milliseconds: 300)));
  testWidgets(
      'mouse second press near the inter-tap deadline still zooms',
      (tester) => expectHeldZoom(tester,
          kind: PointerDeviceKind.mouse,
          betweenTaps: const Duration(milliseconds: 200),
          hold: const Duration(milliseconds: 300)));

  testWidgets('an immediate distant drag pans instead of zooming',
      (tester) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(TestApp(controller: controller));
    final center = tester.getCenter(find.byType(FlutterMap));
    final zoom = controller.camera.zoom;
    final position = controller.camera.center;
    await tester.tapAt(center.translate(-60, 0));
    await tester.pump(const Duration(milliseconds: 50));
    final second = await tester.startGesture(center.translate(60, 0));
    await second.moveBy(const Offset(0, -20));
    await second.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(controller.camera.zoom, zoom);
    expect(controller.camera.center, isNot(position));
    await second.up();
    await tester.pumpAndSettle();
  });

  testWidgets('cancelling the held second press leaves the next drag ordinary',
      (tester) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(TestApp(controller: controller));
    final center = tester.getCenter(find.byType(FlutterMap));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    final second = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 150));
    await second.cancel();
    final zoom = controller.camera.zoom;
    final position = controller.camera.center;
    final next = await tester.startGesture(center);
    await next.moveBy(const Offset(0, -20));
    await next.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(controller.camera.zoom, zoom);
    expect(controller.camera.center, isNot(position));
    await next.up();
    await tester.pumpAndSettle();
  });

  testWidgets('an extra finger invalidates an armed double-tap drag',
      (tester) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(TestApp(
      controller: controller,
      interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.doubleTapDragZoom | InteractiveFlag.drag),
    ));
    final center = tester.getCenter(find.byType(FlutterMap));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    final second = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 150));
    final extra = await tester.startGesture(center.translate(20, 0));
    final zoom = controller.camera.zoom;
    await second.moveBy(const Offset(0, -20));
    await second.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(controller.camera.zoom, zoom);
    await extra.up();
    await second.up();
    await tester.pumpAndSettle();
  });

  testWidgets('an extra finger does not turn a held press into double-tap zoom',
      (tester) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(TestApp(controller: controller));
    final center = tester.getCenter(find.byType(FlutterMap));
    final zoom = controller.camera.zoom;
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    final second = await tester.startGesture(center);
    final extra = await tester.startGesture(center.translate(20, 0));
    await extra.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, zoom);
  });

  testWidgets('ordinary double tap zooms only on the second release',
      (tester) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(TestApp(controller: controller));
    final center = tester.getCenter(find.byType(FlutterMap));
    final zoom = controller.camera.zoom;
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 200));
    final second = await tester.startGesture(center);
    await tester.pump(const Duration(seconds: 1));
    expect(controller.camera.zoom, zoom);
    await second.up();
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, zoom + 1);
  });

  testWidgets('a single held press still invokes the long-press callback',
      (tester) async {
    var longPresses = 0;
    final controller = MapController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(TestApp(
      controller: controller,
      onLongPress: (_, __) => longPresses++,
    ));
    final center = tester.getCenter(find.byType(FlutterMap));
    final zoom = controller.camera.zoom;
    final press = await tester.startGesture(center);
    await tester.pump(const Duration(seconds: 1));
    expect(longPresses, 1);
    expect(controller.camera.zoom, zoom);
    await press.up();
    await tester.pumpAndSettle();
    expect(longPresses, 1);
  });
}
