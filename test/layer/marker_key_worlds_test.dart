import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/test_tile_provider.dart';

void main() {
  testWidgets(
    'a keyed marker repeated across worlds does not produce duplicate keys (#2229)',
    (tester) async {
      const key = Key('m-1');
      final markers = <Marker>[
        const Marker(
          key: key,
          width: 20,
          height: 20,
          point: LatLng(0, 0),
          child: FlutterLogo(),
        ),
      ];

      // A wide viewport at low zoom shows the world several times, so a keyed
      // marker is drawn once per visible world. Before the fix, those copies
      // shared m.key and the layer's Stack threw "Duplicate keys".
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 900,
                height: 200,
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(0, 0),
                    initialZoom: 0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      tileProvider: TestTileProvider(),
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // The marker really is drawn more than once (worlds repeated).
      expect(
        tester.widgetList(find.byType(FlutterLogo)).length,
        greaterThan(1),
      );
      // The main world keeps the caller's key, so find.byKey resolves to one.
      expect(find.byKey(key), findsOneWidget);
    },
  );
}
