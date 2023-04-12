import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'test_utils/mocks.dart';
import 'test_utils/test_app.dart';

void main() {
  setupMocks();

  testWidgets('flutter_map', (tester) async {
    final markers = <Marker>[
      Marker(
        width: 80,
        height: 80,
        point: LatLng(45.5231, -122.6765),
        builder: (_) => const FlutterLogo(),
      ),
      Marker(
        width: 80,
        height: 80,
        point: LatLng(40, -120), // not visible
        builder: (_) => const FlutterLogo(),
      ),
    ];

    await tester.pumpWidget(TestApp(markers: markers));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(TileLayer), findsOneWidget);
    expect(find.byType(RawImage), findsWidgets);
    expect(find.byType(MarkerLayer), findsWidgets);
    expect(find.byType(FlutterLogo), findsOneWidget);
  });
}
