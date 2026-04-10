import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/scroll_zoom.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/test_app.dart';
import '../test_utils/test_tile_provider.dart';

/// Sends a scroll event to the center of the FlutterMap widget.
Future<void> _scroll(WidgetTester tester, {required double dy}) async {
  final center = tester.getCenter(find.byType(FlutterMap));
  await tester.sendEventToBinding(
    PointerScrollEvent(position: center, scrollDelta: Offset(0, dy)),
  );
}

/// Some of these tests inject `TestWidgetsFlutterBinding.instance.clock.now`
/// into [ScrollZoomHandler]. [ScrollZoomHandler] uses
/// `DateTime.now()` in normal operation, which advances in real-time and
/// doesn't care about pumps, which would make testing impossible here.
/// Also, you can't put it into `setUp()` or `setUpAll()` because you can't
/// access `TestWidgetsFlutterBinding.instance.clock` there.
void main() {
  group('ScrollZoomOptions', () {
    test('default values', () {
      const options = ScrollZoomOptions();
      expect(options.smoothZooming, isTrue);
      expect(options.wheelZoomRate, 1 / 450);
      expect(options.trackpadZoomRate, 1 / 100);
      expect(options.animationDuration, const Duration(milliseconds: 200));
    });

    test('snapping constructor disables smooth zooming', () {
      const options = ScrollZoomOptions.snapping();
      expect(options.smoothZooming, isFalse);
    });

    test('equality', () {
      const a = ScrollZoomOptions();
      const b = ScrollZoomOptions();
      const c = ScrollZoomOptions(wheelZoomRate: 1 / 200);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    group('assertions', () {
      test('rejects non-positive wheelZoomRate', () {
        expect(
          () => ScrollZoomOptions(wheelZoomRate: 0),
          throwsA(isA<AssertionError>()),
        );
        expect(
          () => ScrollZoomOptions(wheelZoomRate: -1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('rejects non-positive trackpadZoomRate', () {
        expect(
          () => ScrollZoomOptions(trackpadZoomRate: 0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('rejects non-positive trackpadZoomRate (negative)', () {
        expect(
          () => ScrollZoomOptions(trackpadZoomRate: -0.5),
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });

  group('Scroll zoom - snap mode', () {
    testWidgets('zooms in immediately on scroll up', (tester) async {
      final controller = MapController();
      await tester.pumpWidget(TestApp(
        controller: controller,
        interactionOptions: const InteractionOptions(
          scrollZoomOptions: ScrollZoomOptions.snapping(),
        ),
      ));

      final initialZoom = controller.camera.zoom;

      await _scroll(tester, dy: -100);
      await tester.pump();
      final newZoom = controller.camera.zoom;
      expect(newZoom, greaterThan(initialZoom));

      // Make sure zoom doesn't change after 1 more frame
      await tester.pump();
      expect(controller.camera.zoom, equals(newZoom));
    });

    testWidgets('zooms out immediately on scroll down', (tester) async {
      final controller = MapController();
      await tester.pumpWidget(TestApp(
        controller: controller,
        interactionOptions: const InteractionOptions(
          scrollZoomOptions: ScrollZoomOptions.snapping(),
        ),
      ));

      final initialZoom = controller.camera.zoom;

      await _scroll(tester, dy: 100);
      await tester.pump();
      final newZoom = controller.camera.zoom;
      expect(newZoom, lessThan(initialZoom));

      // Make sure zoom doesn't change after 1 more frame
      await tester.pump();
      expect(controller.camera.zoom, equals(newZoom));
    });
  });

  group('Scroll zoom - smooth mode', () {
    testWidgets('zooms in with animation on single mouse wheel scroll up',
        (tester) async {
      ScrollZoomHandler.currentTimestamp =
          TestWidgetsFlutterBinding.instance.clock.now;
      final controller = MapController();
      await tester.pumpWidget(TestApp(controller: controller));

      final initialZoom = controller.camera.zoom;
      await _scroll(tester, dy: -100);

      await tester.pump(const Duration(milliseconds: 20));
      expect(controller.camera.zoom, equals(initialZoom));

      // After 40 milliseconds, this scroll should be detected as a scroll wheel
      // and the animation should have started.
      await tester.pump(const Duration(milliseconds: 20));
      final midZoom = controller.camera.zoom;
      expect(midZoom, greaterThan(initialZoom));

      // Animation should end, zoom should be greater still.
      await tester.pumpAndSettle();
      expect(controller.camera.zoom, greaterThan(midZoom));
    });

    testWidgets('zooms out with animation on single mouse wheel scroll down',
        (tester) async {
      ScrollZoomHandler.currentTimestamp =
          TestWidgetsFlutterBinding.instance.clock.now;
      final controller = MapController();
      await tester.pumpWidget(TestApp(controller: controller));

      final initialZoom = controller.camera.zoom;
      await _scroll(tester, dy: 100);

      await tester.pump(const Duration(milliseconds: 20));
      expect(controller.camera.zoom, equals(initialZoom));

      // After 40 milliseconds, this scroll should be detected as a scroll wheel
      // and the animation should have started.
      await tester.pump(const Duration(milliseconds: 20));
      final midZoom = controller.camera.zoom;
      expect(midZoom, lessThan(initialZoom));

      // Animation should end, zoom should be lesser still.
      await tester.pumpAndSettle();
      expect(controller.camera.zoom, lessThan(midZoom));
    });

    testWidgets('zooms in without animation on single trackpad scroll up',
        (tester) async {
      ScrollZoomHandler.currentTimestamp =
          TestWidgetsFlutterBinding.instance.clock.now;
      final controller = MapController();
      await tester.pumpWidget(TestApp(controller: controller));

      final initialZoom = controller.camera.zoom;
      await _scroll(tester, dy: -3.99);

      // This scroll should have been immediately detected as a trackpad and
      // should zoom without animation.
      await tester.pump();
      final newZoom = controller.camera.zoom;
      expect(newZoom, greaterThan(initialZoom));

      await tester.pump(const Duration(milliseconds: 1000));
      expect(controller.camera.zoom, equals(newZoom));
    });

    testWidgets('zooms out without animation on multiple trackpad scroll up',
        (tester) async {
      ScrollZoomHandler.currentTimestamp =
          TestWidgetsFlutterBinding.instance.clock.now;
      final controller = MapController();
      await tester.pumpWidget(TestApp(controller: controller));

      final initialZoom = controller.camera.zoom;

      // The first scroll has high delta, but the next one comes sufficiently
      // quick so it should still be detected as a trackpad. Honestly, this
      // is kind of an extreme scenario that will most likely never happen, but
      // a test still needs to cover this case (and adapted later if necessary)
      await _scroll(tester, dy: 120);
      await tester.pump(const Duration(milliseconds: 39));
      await _scroll(tester, dy: 3);
      await tester.pump();

      final newZoom = controller.camera.zoom;
      expect(newZoom, lessThan(initialZoom));

      // This scroll should have been detected as a trackpad and there should be
      // no animation.
      await tester.pump(const Duration(milliseconds: 1000));
      expect(controller.camera.zoom, equals(newZoom));
    });

    testWidgets('respects min/max zoom', (tester) async {
      ScrollZoomHandler.currentTimestamp =
          TestWidgetsFlutterBinding.instance.clock.now;
      final controller = MapController();
      // TODO: consider modifying TestApp to accept a child (FlutterMap) as parameter
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: FlutterMap(
                mapController: controller,
                options: const MapOptions(
                  initialCenter: LatLng(45.5231, -122.6765),
                  initialZoom: 4,
                  minZoom: 2,
                  maxZoom: 10.5,
                ),
                children: [TileLayer(tileProvider: TestTileProvider())],
              ),
            ),
          ),
        ),
      ));

      // Scroll up a lot
      for (var i = 0; i < 100; i++) {
        await _scroll(tester, dy: -100);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // Should not exceed maxZoom
      expect(controller.camera.zoom, lessThanOrEqualTo(10.5));

      // Scroll down a lot
      for (var i = 0; i < 100; i++) {
        await _scroll(tester, dy: 100);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // Should not go below minZoom
      expect(controller.camera.zoom, greaterThanOrEqualTo(2));
    });

    testWidgets('custom animation duration is respected', (tester) async {
      ScrollZoomHandler.currentTimestamp =
          TestWidgetsFlutterBinding.instance.clock.now;
      final controller = MapController();
      await tester.pumpWidget(TestApp(
        controller: controller,
        interactionOptions: const InteractionOptions(
          scrollZoomOptions: ScrollZoomOptions(
            animationDuration: Duration(milliseconds: 1000),
          ),
        ),
      ));

      final initialZoom = controller.camera.zoom;
      await _scroll(tester, dy: -100);

      // Wait for scroll wheel detection + less than animation duration
      await tester.pump(const Duration(milliseconds: 40 + 400));
      final midZoom = controller.camera.zoom;
      expect(midZoom, greaterThan(initialZoom));

      // Wait until exactly the animation's end
      await tester.pump(const Duration(milliseconds: 600));
      final finalZoom = controller.camera.zoom;
      expect(finalZoom, greaterThan(midZoom));

      // Zoom should not change anymore
      await tester.pump(const Duration(milliseconds: 1000));
      final zoom = controller.camera.zoom;
      expect(zoom, equals(finalZoom));
    });
  });

  group('Scroll zoom - zoom anchor', () {
    testWidgets('zooms toward cursor position', (tester) async {
      ScrollZoomHandler.currentTimestamp =
          TestWidgetsFlutterBinding.instance.clock.now;
      final controller = MapController();
      await tester.pumpWidget(TestApp(controller: controller));

      final initialZoom = controller.camera.zoom;

      final mapRect = tester.getRect(find.byType(FlutterMap));
      // Put cursor at 1/4 the size of the map
      final screenPoint = (mapRect.topLeft * 3 + mapRect.bottomRight) / 4;
      final mapScreenPoint = screenPoint - mapRect.topLeft;
      final focusLatLng =
          controller.camera.screenOffsetToLatLng(mapScreenPoint);

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: screenPoint,
          scrollDelta: const Offset(0, -100),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1000));

      expect(controller.camera.zoom, greaterThan(initialZoom));

      final newFocusLatLng =
          controller.camera.screenOffsetToLatLng(mapScreenPoint);

      expect(focusLatLng.latitude, moreOrLessEquals(newFocusLatLng.latitude));
      expect(focusLatLng.longitude, moreOrLessEquals(newFocusLatLng.longitude));
    });
  });

  group('Scroll zoom - events', () {
    testWidgets('emits MapEventScrollZoom', (tester) async {
      final controller = MapController();
      final events = <MapEvent>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: FlutterMap(
                mapController: controller,
                options: MapOptions(
                  initialCenter: const LatLng(45.5231, -122.6765),
                  initialZoom: 10,
                  onMapEvent: events.add,
                  interactionOptions: const InteractionOptions(
                    scrollZoomOptions: ScrollZoomOptions.snapping(),
                  ),
                ),
                children: [TileLayer(tileProvider: TestTileProvider())],
              ),
            ),
          ),
        ),
      ));

      await _scroll(tester, dy: -100);
      await tester.pump();

      expect(
        events.whereType<MapEventScrollWheelZoom>(),
        isNotEmpty,
        reason: 'Should emit MapEventScrollZoom on scroll',
      );
    });
  });
}
