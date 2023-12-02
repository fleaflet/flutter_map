import 'package:flutter/material.dart';
import 'package:flutter_map/src/geo/latlng.dart';
import 'package:flutter_map/src/layer/polygon_layer/polygon_layer.dart';
import 'package:flutter_map/src/map/widget.dart';
import 'package:flutter_test/flutter_test.dart';

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
            (lat: 55.5, lon: 0.09),
            (lat: 54.3498, lon: 6.2603),
            (lat: 52.8566, lon: 2.3522),
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
    const clockwise = <LatLng>[
      (lat: 30, lon: 20),
      (lat: 30, lon: 30),
      (lat: 20, lon: 30),
      (lat: 20, lon: 20),
    ];
    expect(isClockwise(clockwise), isTrue);
    expect(isClockwise(clockwise.reversed.toList()), isFalse);
  });
}
