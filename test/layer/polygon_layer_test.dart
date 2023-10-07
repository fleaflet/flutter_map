import 'package:flutter/material.dart';
import 'package:flutter_map/src/layer/polygon_layer/polygon_layer.dart';
import 'package:flutter_map/src/map/widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/test_app.dart';

void main() {
  testWidgets('test polygon layer', (tester) async {
    final polygons = <Polygon>[
      for (int i = 0; i < 1; ++i)
        Polygon(
          isFilled: true,
          color: Colors.purple,
          borderColor: Colors.purple,
          borderStrokeWidth: 4,
          label: '$i',
          points: const [
            LatLng(55.5, -0.09),
            LatLng(54.3498, -6.2603),
            LatLng(52.8566, 2.3522),
          ],
        ),
    ];

    await tester.pumpWidget(TestApp(polygons: polygons));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolygonLayer), findsOneWidget);

    // Assert that batching works and all polygons are drawn into the same
    // CustomPaint/Canvas.
    expect(
        find.descendant(
            of: find.byType(PolygonLayer), matching: find.byType(CustomPaint)),
        findsOneWidget);
  });

  test('polygon normal/rotation', () {
    const clockwise = [
      LatLng(30, 20),
      LatLng(30, 30),
      LatLng(20, 30),
      LatLng(20, 20),
    ];
    expect(isClockwise(clockwise), isTrue);
    expect(isClockwise(clockwise.reversed.toList()), isFalse);
  });
}
