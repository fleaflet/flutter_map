import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  group('map gesture semantics', () {
    testWidgets(
      'the map does not publish a map-sized tap semantics action '
      '(regression test: a tappable node covering the map made semantic taps '
      'report the map centre instead of the tap position, and on web its '
      'pointer-events swallowed the mouse events of any HtmlElementView '
      'layered above the map - '
      'https://github.com/fleaflet/flutter_map/issues/2176)',
      (tester) async {
        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            home: FlutterMap(
              options: const MapOptions(),
              children: const [],
            ),
          ),
        );

        final actionable = <SemanticsNode>[];
        void visit(SemanticsNode node) {
          final data = node.getSemanticsData();
          if (data.hasAction(SemanticsAction.tap) ||
              data.hasAction(SemanticsAction.longPress)) {
            actionable.add(node);
          }
          node.visitChildren((child) {
            visit(child);
            return true;
          });
        }

        final root = tester.binding.pipelineOwner.semanticsOwner!
            .rootSemanticsNode!;
        visit(root);
        semantics.dispose();

        expect(actionable, isEmpty);
      },
    );
  });
}
