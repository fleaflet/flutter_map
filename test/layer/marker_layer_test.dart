import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/mocks.dart';
import '../test_utils/test_app.dart';

void main() {
  setupMocks();

  testWidgets('test marker key', (tester) async {
    const key = Key('m-1');

    final markers = <Marker>[
      Marker(
        key: key,
        width: 80,
        height: 80,
        point: LatLng(45.5231, -122.6765),
        builder: (_) => const FlutterLogo(),
      ),
    ];

    await tester.pumpWidget(TestApp(markers: markers));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(MarkerLayer), findsWidgets);
    expect(find.byKey(key), findsOneWidget);
  });
}
