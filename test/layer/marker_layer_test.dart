import 'package:flutter/material.dart';
import 'package:flutter_map/src/layer/marker_layer.dart';
import 'package:flutter_map/src/map/widget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils/test_app.dart';

void main() {
  testWidgets('test marker key', (tester) async {
    const key = Key('m-1');

    final markers = <Marker>[
      const Marker(
        key: key,
        width: 80,
        height: 80,
        point: (lat: 45.5231, lon: 122.6765),
        child: FlutterLogo(),
      ),
    ];

    await tester.pumpWidget(TestApp(markers: markers));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(MarkerLayer), findsWidgets);
    expect(find.byKey(key), findsOneWidget);
  });
}
