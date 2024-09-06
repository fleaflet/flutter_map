import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

typedef HitValue = ({String title, String subtitle});

class CirclePage extends StatefulWidget {
  static const String route = '/circle';

  const CirclePage({super.key});

  @override
  State<CirclePage> createState() => _CirclePageState();
}

class _CirclePageState extends State<CirclePage> {
  final LayerHitNotifier<HitValue> _hitNotifier = ValueNotifier(null);
  List<HitValue>? _prevHitValues;
  List<CircleMarker<HitValue>>? _hoverCircles;

  final _circlesRaw = <CircleMarker<HitValue>>[
    CircleMarker(
      point: const LatLng(51.5, -0.09),
      color: Colors.white.withOpacity(0.7),
      borderColor: Colors.black,
      borderStrokeWidth: 2,
      useRadiusInMeter: false,
      radius: 100,
      hitValue: (title: 'White', subtitle: 'Radius in logical pixels'),
    ),
    CircleMarker(
      point: const LatLng(51.5, -0.09),
      color: Colors.black.withOpacity(0.7),
      borderColor: Colors.black,
      borderStrokeWidth: 2,
      useRadiusInMeter: false,
      radius: 50,
      hitValue: (
        title: 'Black',
        subtitle: 'Radius in logical pixels, should be above white.',
      ),
    ),
    CircleMarker(
      point: const LatLng(51.4937, -0.6638),
      // Dorney Lake is ~2km long
      color: Colors.green.withOpacity(0.9),
      borderColor: Colors.black,
      borderStrokeWidth: 2,
      useRadiusInMeter: true,
      radius: 1000, // 1000 meters
      hitValue: (
        title: 'Green',
        subtitle: 'Radius in meters, calibrated over ~2km rowing lake'
      ),
    ),
  ];
  late final _circles =
      Map.fromEntries(_circlesRaw.map((e) => MapEntry(e.hitValue, e)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Circles')),
      drawer: const MenuDrawer(CirclePage.route),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(51.5, -0.09),
          initialZoom: 11,
        ),
        children: [
          openStreetMapTileLayer,
          MouseRegion(
            hitTestBehavior: HitTestBehavior.deferToChild,
            cursor: SystemMouseCursors.click,
            onHover: (_) {
              final hitValues = _hitNotifier.value?.hitValues.toList();
              if (hitValues == null) return;

              if (listEquals(hitValues, _prevHitValues)) return;
              _prevHitValues = hitValues;

              final hoverCircles = hitValues.map((v) {
                final original = _circles[v]!;

                return CircleMarker<HitValue>(
                  point: original.point,
                  radius: original.radius + 6.5,
                  useRadiusInMeter: original.useRadiusInMeter,
                  color: Colors.transparent,
                  borderStrokeWidth: 15,
                  borderColor: Colors.green,
                );
              }).toList();
              setState(() => _hoverCircles = hoverCircles);
            },
            onExit: (_) {
              _prevHitValues = null;
              setState(() => _hoverCircles = null);
            },
            child: GestureDetector(
              onTap: () => _openTouchedCirclesModal(
                'Tapped',
                _hitNotifier.value!.hitValues,
                _hitNotifier.value!.coordinate,
              ),
              onLongPress: () => _openTouchedCirclesModal(
                'Long pressed',
                _hitNotifier.value!.hitValues,
                _hitNotifier.value!.coordinate,
              ),
              onSecondaryTap: () => _openTouchedCirclesModal(
                'Secondary tapped',
                _hitNotifier.value!.hitValues,
                _hitNotifier.value!.coordinate,
              ),
              child: CircleLayer(
                hitNotifier: _hitNotifier,
                circles: [
                  ..._circlesRaw,
                  ...?_hoverCircles,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openTouchedCirclesModal(
    String eventType,
    List<HitValue> tappedCircles,
    LatLng coords,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tapped Circle(s)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '$eventType at point: (${coords.latitude.toStringAsFixed(6)}, ${coords.longitude.toStringAsFixed(6)})',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemBuilder: (context, index) {
                  final tappedLineData = tappedCircles[index];
                  return ListTile(
                    leading: index == 0
                        ? const Icon(Icons.vertical_align_top)
                        : index == tappedCircles.length - 1
                            ? const Icon(Icons.vertical_align_bottom)
                            : const SizedBox.shrink(),
                    title: Text(tappedLineData.title),
                    subtitle: Text(tappedLineData.subtitle),
                    dense: true,
                  );
                },
                itemCount: tappedCircles.length,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
