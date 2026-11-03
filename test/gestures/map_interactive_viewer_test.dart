import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/map_interactive_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  group('MapInteractiveViewerState.dispose', () {
    Widget map() => const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(size: Size(800, 600)),
            child: FlutterMap(children: []),
          ),
        );

    testWidgets('disposes every ValueNotifier<bool> it created',
        (tester) async {
      final created = <Object>{};
      final disposed = <Object>{};
      void onEvent(ObjectEvent event) {
        if (event.object is! ValueNotifier<bool>) return;
        (event is ObjectCreated ? created : disposed).add(event.object);
      }

      FlutterMemoryAllocations.instance.addListener(onEvent);
      addTearDown(
        () => FlutterMemoryAllocations.instance.removeListener(onEvent),
      );

      await tester.pumpWidget(map());
      await tester.pumpWidget(const SizedBox.shrink());

      expect(created, isNotEmpty);
      expect(created.difference(disposed), isEmpty);
    });

    testWidgets('can be torn down while a keyboard leap is in progress',
        (tester) async {
      await tester.pumpWidget(map());
      await tester.pump();

      // A short press starts a leap, which writes the leaping notifiers from
      // the animation's listener until the curve reaches its leap maximum.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 16));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });
  });
}
