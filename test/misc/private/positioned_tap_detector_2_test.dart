import 'package:flutter/material.dart';
import 'package:flutter_map/src/gestures/positioned_tap_detector_2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test tap is detected where expected.', (tester) async {
    const screenSize = Size(400, 400);
    await tester.binding.setSurfaceSize(screenSize);

    // PositionedTapDetector2 fills the full screen.
    Offset? lastTap;
    final widget = PositionedTapDetector2(
      onTap: (position) => lastTap = position.relative,
      child: SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: Container(
          color: Colors.red,
        ),
      ),
    );

    await tester.pumpWidget(widget);

    Future<void> tap(Offset pos) async {
      lastTap = null;
      await tester.tapAt(pos);
      expect(lastTap, pos);
    }

    // Tap top left
    await tap(Offset.zero);
    // Tap middle
    await tap(Offset(screenSize.width / 2, screenSize.height / 2));
    // Tap bottom right
    await tap(Offset(screenSize.width - 1, screenSize.height - 1));
  });

  testWidgets('Test tap is detected where expected with scale and offset.',
      (tester) async {
    const screenSize = Size(400, 400);
    await tester.binding.setSurfaceSize(screenSize);

    Offset? lastTap;
    // The Transform.scale fills the screen, but the PositionedTapDetector2
    // occupies the center, with height of 200 (0.5 * 400) and width 400.
    final widget = Transform.scale(
      scaleY: 0.5,
      child: PositionedTapDetector2(
        onTap: (position) => lastTap = position.relative,
        child: SizedBox(
          width: screenSize.width,
          height: screenSize.height,
          child: Container(
            color: Colors.red,
          ),
        ),
      ),
    );

    await tester.pumpWidget(widget);

    // On the screen the PositionedTapDetector2 is actually 400x200, but the
    // widget thinks its 400x400.
    expect(screenSize, tester.getSize(find.byType(SizedBox)));

    Future<void> tap(Offset pos, Offset expected) async {
      lastTap = null;
      await tester.tapAt(pos);
      expect(lastTap, expected);
    }

    // Tap top left of PositionedTapDetector2 which should be 0,0.
    await tap(const Offset(0, 100), Offset.zero);

    // Tap bottom right of PositionedTapDetector2
    await tap(const Offset(400 - 1, 300 - 0.5),
        Offset(screenSize.width - 1, screenSize.height - 1));
  });
}
