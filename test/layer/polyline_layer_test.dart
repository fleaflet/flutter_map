import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/test_app.dart';

void main() {
  testWidgets('test polyline layer', (tester) async {
    final polylines = <Polyline>[
      for (int i = 0; i < 10; i++)
        Polyline(
          points: [
            LatLng(50.5 + i, -0.09),
            LatLng(51.3498 + i, -6.2603),
            LatLng(53.8566 + i, 2.3522),
          ],
          strokeWidth: 4,
          color: Colors.amber,
        ),
    ];

    await tester.pumpWidget(TestApp(polylines: polylines));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolylineLayer), findsWidgets);

    // Assert that batching works and all Polylines are drawn into the same
    // CustomPaint/Canvas.
    expect(
        find.descendant(
            of: find.byType(PolylineLayer), matching: find.byType(CustomPaint)),
        findsOneWidget);
  });

  group('effects', () {
    const lineColor = Color(0xFF2196F3);
    const glowColor = Color(0xFFFF9800);
    const shadowColor = Color(0x80000000);

    RenderObject paintedLayer(WidgetTester tester) => tester.renderObject(
          find.descendant(
            of: find.byType(PolylineLayer),
            matching: find.byType(CustomPaint),
          ),
        );

    Polyline line({ShapeGlow? glow, ShapeShadow? shadow}) => Polyline(
          points: const [
            LatLng(45.5231, -122.6865),
            LatLng(45.5231, -122.6665)
          ],
          strokeWidth: 4,
          color: lineColor,
          glow: glow,
          shadow: shadow,
        );

    testWidgets('paints shadow, then glow, then the line', (tester) async {
      await tester.pumpWidget(
        TestApp(
          polylines: [
            line(
              glow: const ShapeGlow(color: glowColor),
              shadow: const ShapeShadow(color: shadowColor),
            ),
          ],
        ),
      );

      expect(
        paintedLayer(tester),
        paints
          ..save()
          ..translate(x: 0, y: 2)
          ..path(color: shadowColor, strokeWidth: 4)
          ..restore()
          ..path(color: glowColor, strokeWidth: 4)
          ..path(color: lineColor, strokeWidth: 4),
      );
    });

    testWidgets('paints only the line without effects', (tester) async {
      await tester.pumpWidget(TestApp(polylines: [line()]));

      expect(paintedLayer(tester), paintsExactlyCountTimes(#drawPath, 1));
    });

    test('effects take part in equality and batching', () {
      const glow = ShapeGlow(color: glowColor);

      expect(line(glow: glow), line(glow: glow));
      expect(line(glow: glow), isNot(line()));
      expect(line(glow: glow).renderHashCode, isNot(line().renderHashCode));
    });
  });
}
