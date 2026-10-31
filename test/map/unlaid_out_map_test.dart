import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// Builds [map] on a route that an opaque route covers from the very first
/// frame.
///
/// The `Overlay` builds the covered route but never lays it out, so the
/// `LayoutBuilder` inside `FlutterMap` never runs and the map's
/// `MapInteractiveViewer` is never created - while `onMapReady`, scheduled
/// from `FlutterMap`'s `initState`, still fires after the first frame.
///
/// This happens whenever an app is launched straight into a deeper screen,
/// for example from a deep link or a notification, with the map underneath.
Widget _coveredMap(Widget map) => MaterialApp(
      // Without `onGenerateRoute`, `MaterialApp` builds no `Navigator` and
      // ignores `onGenerateInitialRoutes`.
      onGenerateRoute: (_) => null,
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute<void>(builder: (_) => Scaffold(body: map)),
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('cover')),
        ),
      ],
    );

Future<void> _uncover(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator)).pop();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'moving the camera from onMapReady does not throw when the map has not '
    'been laid out, and the move is kept',
    (tester) async {
      final controller = MapController();
      addTearDown(controller.dispose);
      const destination = LatLng(52, 9);
      var ready = false;

      await tester.pumpWidget(
        _coveredMap(
          FlutterMap(
            mapController: controller,
            options: MapOptions(
              onMapReady: () {
                ready = true;
                controller.move(destination, 15);
              },
            ),
            children: const [],
          ),
        ),
      );
      await tester.pump();

      expect(ready, isTrue);
      expect(tester.takeException(), isNull);

      await _uncover(tester);

      expect(tester.takeException(), isNull);
      expect(controller.camera.center, destination);
      expect(controller.camera.zoom, 15);
    },
  );

  testWidgets(
    'changing the interaction options before the map has been laid out does '
    'not throw, and the new options apply once it is',
    (tester) async {
      final controller = MapController();
      addTearDown(controller.dispose);
      final interactive = ValueNotifier(false);
      addTearDown(interactive.dispose);

      await tester.pumpWidget(
        _coveredMap(
          ValueListenableBuilder(
            valueListenable: interactive,
            builder: (_, isInteractive, __) => FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: const LatLng(0, 0),
                interactionOptions: InteractionOptions(
                  flags: isInteractive
                      ? InteractiveFlag.all
                      : InteractiveFlag.none,
                ),
              ),
              children: const [],
            ),
          ),
        ),
      );
      await tester.pump();

      interactive.value = true;
      await tester.pump();

      expect(tester.takeException(), isNull);

      await _uncover(tester);
      await tester.drag(find.byType(FlutterMap), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(controller.camera.center, isNot(const LatLng(0, 0)));
    },
  );
}
