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

  testWidgets('multicolor polyline renders without errors', (tester) async {
    final polylines = <Polyline>[
      MulticolorPolyline(
        points: const [
          LatLng(50.5, -0.09),
          LatLng(51.3498, -6.2603),
          LatLng(53.8566, 2.3522),
        ],
        vertexColors: const [
          Colors.red,
          Colors.orange,
          Colors.blue,
        ],
        strokeWidth: 6,
      ),
    ];

    await tester.pumpWidget(TestApp(polylines: polylines));

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolylineLayer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multicolor polyline falls back to defaultColor', (tester) async {
    final polylines = <Polyline>[
      MulticolorPolyline(
        points: const [
          LatLng(52.5, -0.09),
          LatLng(53.3498, -6.2603),
          LatLng(55.8566, 2.3522),
        ],
        defaultColor: Colors.purple,
        strokeWidth: 5,
      ),
    ];

    await tester.pumpWidget(TestApp(polylines: polylines));

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolylineLayer), findsOneWidget);
    expect(tester.takeException(), isNull);

    final polyline = polylines.first as MulticolorPolyline;
    expect(polyline.vertexColors, isNull);
    expect(polyline.color, equals(Colors.purple));
    expect(polyline.resolvedVertexColors, everyElement(equals(Colors.purple)));
  });
}
