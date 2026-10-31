import 'package:flutter/gestures.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/map_interactive_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils/test_app.dart';

void main() {
  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets(
      'double-tap drag zoom remains active while the second $kind pointer is '
      'held',
      (tester) async {
        final controller = MapController();
        await tester.pumpWidget(
          TestApp(
            controller: controller,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.doubleTapDragZoom,
            ),
          ),
        );

        final center = tester.getCenter(find.byType(FlutterMap));
        final firstTap = TestPointer(1, kind);
        tester.binding.handlePointerEvent(firstTap.down(center));
        tester.binding.handlePointerEvent(firstTap.up());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final secondTap = TestPointer(2, kind);
        tester.binding.handlePointerEvent(secondTap.down(center));
        await tester.pump(const Duration(milliseconds: 300));

        final zoomBeforeDrag = controller.camera.zoom;
        final centerBeforeDrag = controller.camera.center;
        tester.binding.handlePointerEvent(
          secondTap.move(center.translate(0, -20)),
        );
        tester.binding.handlePointerEvent(
          secondTap.move(center.translate(0, -100)),
        );
        tester.binding.handlePointerEvent(
          secondTap.move(center.translate(0, -150)),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(controller.camera.zoom, isNot(zoomBeforeDrag));
        expect(controller.camera.center, centerBeforeDrag);

        tester.binding.handlePointerEvent(secondTap.up());
      },
    );
  }

  testWidgets('a distant second tap does not enable double-tap drag zoom',
      (tester) async {
    final controller = MapController();
    await tester.pumpWidget(
      TestApp(
        controller: controller,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.doubleTapDragZoom,
        ),
      ),
    );

    final center = tester.getCenter(find.byType(FlutterMap));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 100));

    final secondTap = await tester.startGesture(center.translate(100, 0));
    await tester.pump(const Duration(milliseconds: 300));
    final zoomBeforeDrag = controller.camera.zoom;
    await secondTap.moveBy(const Offset(0, -150));
    await tester.pump();

    expect(controller.camera.zoom, zoomBeforeDrag);
    await secondTap.up();
  });

  testWidgets('a second pointer does not enable double-tap drag zoom',
      (tester) async {
    final controller = MapController();
    await tester.pumpWidget(
      TestApp(
        controller: controller,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.doubleTapDragZoom,
        ),
      ),
    );

    final center = tester.getCenter(find.byType(FlutterMap));
    final firstPointer = await tester.startGesture(center);
    final secondPointer = await tester.startGesture(center.translate(10, 0));
    await tester.pump(const Duration(milliseconds: 300));
    final zoomBeforeDrag = controller.camera.zoom;
    await secondPointer.moveBy(const Offset(0, -150));
    await tester.pump();

    expect(controller.camera.zoom, zoomBeforeDrag);
    await firstPointer.up();
    await secondPointer.up();
  });

  group('MapInteractiveViewerState.flingDirection', () {
    test('uses the final segment direction when it has non-zero length', () {
      final direction = MapInteractiveViewerState.flingDirection(
        finalSegment: const Offset(10, 0),
        flingOffset: const Offset(100, 0),
        velocityDirection: const Offset(0, 1),
      );

      expect(direction, const Offset(1, 0));
    });

    test(
      'falls back to the overall drag direction when the final segment has '
      'zero length',
      () {
        final direction = MapInteractiveViewerState.flingDirection(
          finalSegment: Offset.zero,
          flingOffset: const Offset(0, -50),
          velocityDirection: const Offset(1, 0),
        );

        expect(direction, const Offset(0, -1));
      },
    );

    test(
      'falls back to the velocity direction instead of dividing by zero '
      'when both the final segment and the overall drag offset have zero '
      'length (regression test: this previously produced a NaN direction, '
      'which corrupted the camera position - '
      'https://github.com/fleaflet/flutter_map/issues/2199)',
      () {
        final direction = MapInteractiveViewerState.flingDirection(
          finalSegment: Offset.zero,
          flingOffset: Offset.zero,
          velocityDirection: const Offset(0.6, 0.8),
        );

        expect(direction, const Offset(0.6, 0.8));
        expect(direction.dx.isFinite, isTrue);
        expect(direction.dy.isFinite, isTrue);
      },
    );
  });
}
