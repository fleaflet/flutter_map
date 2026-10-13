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

  testWidgets(
    'a keyed marker copy in a repeated world keeps its state across zoom',
    (tester) async {
      final controller = MapController();
      final markers = <Marker>[
        const Marker(
          key: Key('m-1'),
          width: 20,
          height: 20,
          point: LatLng(0, 0),
          child: _StatefulMarker(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 900,
                height: 200,
                child: FlutterMap(
                  mapController: controller,
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

      final before = tester
          .stateList<_StatefulMarkerState>(find.byType(_StatefulMarker))
          .toList();
      // The main world and at least one repeated world are drawn.
      expect(before.length, greaterThan(1));

      // Zooming changes the world width in pixels, but each copy stays in the
      // same world, so its element and state must be kept.
      controller.move(const LatLng(0, 0), 0.5);
      await tester.pump();

      final after = tester
          .stateList<_StatefulMarkerState>(find.byType(_StatefulMarker))
          .toList();
      expect(tester.takeException(), isNull);
      expect(after, orderedEquals(before));
    },
  );
}

class _StatefulMarker extends StatefulWidget {
  const _StatefulMarker();

  @override
  State<_StatefulMarker> createState() => _StatefulMarkerState();
}

class _StatefulMarkerState extends State<_StatefulMarker> {
  @override
  Widget build(BuildContext context) => const FlutterLogo();
}
