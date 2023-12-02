import 'package:flutter/material.dart';
import 'package:flutter_map/src/geo/latlng.dart';
import 'package:flutter_map/src/layer/polyline_layer.dart';
import 'package:flutter_map/src/map/widget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils/test_app.dart';

void main() {
  testWidgets('test polyline layer', (tester) async {
    final polylines = <Polyline>[
      for (int i = 0; i < 10; i++)
        Polyline(
          points: <LatLng>[
            (lat: 50.5 + i, lon: -0.09),
            (lat: 51.3498 + i, lon: -6.2603),
            (lat: 53.8566 + i, lon: 2.3522),
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
}
