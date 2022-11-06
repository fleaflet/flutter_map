import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/mocks.dart';
import '../test_utils/test_app.dart';

void main() {
  setupMocks();

  testWidgets('test polyline key', (tester) async {
    const key = Key('p-1');

    final polylines = <Polyline>[
      Polyline(
        key: key,
        points: [
          LatLng(50.5, -0.09),
          LatLng(51.3498, -6.2603),
          LatLng(53.8566, 2.3522),
        ],
        strokeWidth: 4,
        color: Colors.amber,
      ),
    ];

    await tester.pumpWidget(TestApp(polylines: polylines));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolylineLayer), findsWidgets);
    expect(find.byKey(key), findsOneWidget);
  });
}
