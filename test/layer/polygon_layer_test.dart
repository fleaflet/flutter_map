import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/mocks.dart';
import '../test_utils/test_app.dart';

void main() {
  setupMocks();

  testWidgets('test polygon key', (tester) async {
    final filledPoints = <LatLng>[
      LatLng(55.5, -0.09),
      LatLng(54.3498, -6.2603),
      LatLng(52.8566, 2.3522),
    ];

    const key = Key('p-1');

    final polygon = Polygon(
      key: key,
      points: filledPoints,
      isFilled: true,
      color: Colors.purple,
      borderColor: Colors.purple,
      borderStrokeWidth: 4,
    );

    await tester.pumpWidget(TestApp(polygons: [polygon]));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolygonLayer), findsOneWidget);
    expect(find.byKey(key), findsOneWidget);
  });
}
