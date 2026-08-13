import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/test_app.dart';

void main() {
  testWidgets('test marker key', (tester) async {
    const key = Key('m-1');

    final markers = <Marker>[
      const Marker(
        key: key,
        width: 80,
        height: 80,
        point: LatLng(45.5231, -122.6765),
        child: FlutterLogo(),
      ),
    ];

    await tester.pumpWidget(TestApp(markers: markers));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(MarkerLayer), findsWidgets);
    expect(find.byKey(key), findsOneWidget);
  });

  // #2178 only rejects a non-finite Marker.point. A finite marker plus a
  // non-finite camera still makes Rect.overlaps return true for every world
  // copy, so the wrap loops never stop (OOM / ANR). See #2240.
  testWidgets('non-finite camera rotation does not hang MarkerLayer',
      (tester) async {
    final controller = MapController();
    await tester.pumpWidget(
      MaterialApp(
        home: FlutterMap(
          mapController: controller,
          options: const MapOptions(
            initialCenter: LatLng(16.6, 120.9),
            initialZoom: 12,
          ),
          children: const [
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(16.6, 120.9),
                  width: 40,
                  height: 40,
                  child: SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    controller.rotate(double.nan);
    await tester.pump();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(MarkerLayer), findsOneWidget);
  });
}
