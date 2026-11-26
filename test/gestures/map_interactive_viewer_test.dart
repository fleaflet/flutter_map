import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/map_interactive_viewer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/test_app.dart';

void main() {
  group('fling across the antimeridian', () {
    Future<MapCamera> fling(
      WidgetTester tester,
      int direction,
      CameraConstraint constraint,
    ) async {
      final controller = MapController();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCenter: LatLng(-44.28, direction * 175.0),
              initialZoom: 8,
              cameraConstraint: constraint,
            ),
            children: const [],
          ),
        ),
      );

      await tester.flingFrom(
        tester.getCenter(find.byType(FlutterMap)) + Offset(direction * 300, 0),
        Offset(direction * -650, 0),
        3000,
      );
      await tester.pumpAndSettle();
      return controller.camera;
    }

    for (final direction in [1, -1]) {
      testWidgets('stops at the boundary towards ${direction * 180}°', (
        tester,
      ) async {
        final bounds = LatLngBounds(
          LatLng(-38.82, direction * 164.37),
          LatLng(-49.49, direction * 177.86),
        );
        final camera = await fling(
          tester,
          direction,
          CameraConstraint.contain(bounds: bounds),
        );

        final edge = direction > 0 ? bounds.east : bounds.west;
        final centerX = camera.projectAtZoom(camera.center).dx;
        final viewportEdgeX = centerX + direction * camera.size.width / 2;
        expect(
          viewportEdgeX,
          closeTo(camera.projectAtZoom(LatLng(-44.28, edge)).dx, 1e-6),
        );
      });
    }

    testWidgets('wraps when only latitude is constrained', (tester) async {
      final camera = await fling(
        tester,
        1,
        const CameraConstraint.containLatitude(),
      );
      expect(camera.center.longitude, inExclusiveRange(-180, -170));
    });
  });

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

  testWidgets('a distant second tap does not enable double-tap drag zoom', (
    tester,
  ) async {
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

  testWidgets('a second pointer does not enable double-tap drag zoom', (
    tester,
  ) async {
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
    test('uses the velocity direction when preferred, even when the final '
        'segment has non-zero length (touch input: the velocity is fitted '
        'over multiple recent samples, while the single last pointer segment '
        'is noisy on fast swipes and sends repeated flicks zigzagging '
        'off-axis)', () {
      final direction = MapInteractiveViewerState.flingDirection(
        finalSegment: const Offset(10, 2),
        flingOffset: const Offset(100, 0),
        velocityDirection: const Offset(0, 1),
        preferVelocityDirection: true,
      );

      expect(direction, const Offset(0, 1));
    });

    test('uses the final segment direction when it has non-zero length', () {
      final direction = MapInteractiveViewerState.flingDirection(
        finalSegment: const Offset(10, 0),
        flingOffset: const Offset(100, 0),
        velocityDirection: const Offset(0, 1),
        preferVelocityDirection: false,
      );

      expect(direction, const Offset(1, 0));
    });

    test('falls back to the overall drag direction when the final segment has '
        'zero length', () {
      final direction = MapInteractiveViewerState.flingDirection(
        finalSegment: Offset.zero,
        flingOffset: const Offset(0, -50),
        velocityDirection: const Offset(1, 0),
        preferVelocityDirection: false,
      );

      expect(direction, const Offset(0, -1));
    });

    test('falls back to the velocity direction instead of dividing by zero '
        'when both the final segment and the overall drag offset have zero '
        'length (regression test: this previously produced a NaN direction, '
        'which corrupted the camera position - '
        'https://github.com/fleaflet/flutter_map/issues/2199)', () {
      final direction = MapInteractiveViewerState.flingDirection(
        finalSegment: Offset.zero,
        flingOffset: Offset.zero,
        velocityDirection: const Offset(0.6, 0.8),
        preferVelocityDirection: false,
      );

      expect(direction, const Offset(0.6, 0.8));
      expect(direction.dx.isFinite, isTrue);
      expect(direction.dy.isFinite, isTrue);
    });
  });
}
