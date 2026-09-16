import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/test_app.dart';

void main() {
  testWidgets('test circle marker key', (tester) async {
    const key = Key('c-1');

    final circles = <CircleMarker>[
      CircleMarker(
        key: key,
        point: const LatLng(51.5, -0.09),
        color: Colors.blue.withAlpha(178),
        borderStrokeWidth: 2,
        useRadiusInMeter: true,
        radius: 2000,
      ),
    ];

    await tester.pumpWidget(TestApp(circles: circles));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(CircleLayer), findsOneWidget);

    // Assert that batching works and all circles are drawn into the same
    // CustomPaint/Canvas.
    expect(
        find.descendant(
            of: find.byType(CircleLayer), matching: find.byType(CustomPaint)),
        findsOneWidget);
  });

  group('effects', () {
    const fillColor = Color(0xFF2196F3);
    const borderColor = Color(0xFF0D47A1);
    const glowColor = Color(0xFFFF9800);
    const shadowColor = Color(0x80000000);

    RenderObject paintedLayer(WidgetTester tester) => tester.renderObject(
          find.descendant(
            of: find.byType(CircleLayer),
            matching: find.byType(CustomPaint),
          ),
        );

    testWidgets('paints shadow and glow below the disk', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          circles: [
            CircleMarker(
              point: LatLng(45.5231, -122.6765),
              radius: 20,
              color: fillColor,
              borderStrokeWidth: 4,
              borderColor: borderColor,
              glow: ShapeGlow(color: glowColor),
              shadow: ShapeShadow(color: shadowColor),
            ),
          ],
        ),
      );

      expect(
        paintedLayer(tester),
        paints
          ..save()
          ..translate(x: 0, y: 2)
          ..circle(radius: 22, color: shadowColor, style: PaintingStyle.fill)
          ..restore()
          ..circle(radius: 22, color: glowColor, style: PaintingStyle.fill)
          ..something(_drawsPoints(diameter: 44))
          ..something(_drawsPoints(diameter: 40)),
      );
    });

    testWidgets('follows only the ring when the fill is transparent', (
      tester,
    ) async {
      await tester.pumpWidget(
        const TestApp(
          circles: [
            CircleMarker(
              point: LatLng(45.5231, -122.6765),
              radius: 20,
              color: Color(0x00000000),
              borderStrokeWidth: 4,
              borderColor: borderColor,
              glow: ShapeGlow(color: glowColor),
            ),
          ],
        ),
      );

      expect(
        paintedLayer(tester),
        paints
          ..circle(
            radius: 20,
            color: glowColor,
            style: PaintingStyle.stroke,
            strokeWidth: 4,
          )
          ..circle(radius: 20, color: borderColor, strokeWidth: 4),
      );
    });

    testWidgets('paints no effects when none are set', (tester) async {
      await tester.pumpWidget(
        const TestApp(
          circles: [
            CircleMarker(
              point: LatLng(45.5231, -122.6765),
              radius: 20,
              color: fillColor,
            ),
          ],
        ),
      );

      expect(paintedLayer(tester), paintsExactlyCountTimes(#drawCircle, 0));
    });
  });
}

// The painter reuses one Paint for points, so match on its recorded width
PaintPatternPredicate _drawsPoints({required double diameter}) =>
    (method, arguments) =>
        method == #drawPoints &&
        (arguments[2] as Paint).strokeWidth == diameter;
