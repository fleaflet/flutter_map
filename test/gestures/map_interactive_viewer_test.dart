import 'package:flutter_map/src/gestures/map_interactive_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapInteractiveViewerState.flingDirection', () {
    test(
      'uses the velocity direction when preferred, even when the final '
      'segment has non-zero length (touch input: the velocity is fitted '
      'over multiple recent samples, while the single last pointer segment '
      'is noisy on fast swipes and sends repeated flicks zigzagging '
      'off-axis)',
      () {
        final direction = MapInteractiveViewerState.flingDirection(
          finalSegment: const Offset(10, 2),
          flingOffset: const Offset(100, 0),
          velocityDirection: const Offset(0, 1),
          preferVelocityDirection: true,
        );

        expect(direction, const Offset(0, 1));
      },
    );

    test('uses the final segment direction when it has non-zero length', () {
      final direction = MapInteractiveViewerState.flingDirection(
        finalSegment: const Offset(10, 0),
        flingOffset: const Offset(100, 0),
        velocityDirection: const Offset(0, 1),
        preferVelocityDirection: false,
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
          preferVelocityDirection: false,
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
          preferVelocityDirection: false,
        );

        expect(direction, const Offset(0.6, 0.8));
        expect(direction.dx.isFinite, isTrue);
        expect(direction.dy.isFinite, isTrue);
      },
    );
  });
}
