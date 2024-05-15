import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

typedef HitValue = ({String title, String subtitle});

class PolylinePage extends StatefulWidget {
  static const String route = '/polyline';

  const PolylinePage({super.key});

  @override
  State<PolylinePage> createState() => _PolylinePageState();
}

class _PolylinePageState extends State<PolylinePage> {
  final LayerHitNotifier<HitValue> _hitNotifier = ValueNotifier(null);
  List<HitValue>? _prevHitValues;
  List<Polyline<HitValue>>? _hoverLines;

  final _polylinesRaw = <Polyline<HitValue>>[
    Polyline(
      points: [
        const LatLng(51.5, -0.09),
        const LatLng(53.3498, -6.2603),
        const LatLng(48.8566, 2.3522),
      ],
      strokeWidth: 8,
      color: const Color(0xFF60399E),
      hitValue: (
        title: 'Purple Line',
        subtitle: 'Nothing really special here...',
      ),
    ),
    Polyline(
      points: [
        const LatLng(48.5, -3.09),
        const LatLng(47.3498, -9.2603),
        const LatLng(43.8566, -1.3522),
      ],
      strokeWidth: 16000,
      color: Colors.pink,
      useStrokeWidthInMeter: true,
      hitValue: (
        title: 'Pink Line',
        subtitle: 'Fixed radius in meters instead of pixels',
      ),
    ),
    Polyline(
      points: [
        const LatLng(51.74904, -10.32324),
        const LatLng(54.3498, -6.2603),
        const LatLng(52.8566, 2.3522),
      ],
      strokeWidth: 4,
      gradientColors: [
        const Color(0xffE40203),
        const Color(0xffFEED00),
        const Color(0xff007E2D),
      ],
      hitValue: (
        title: 'Traffic Light Line',
        subtitle: 'Fancy gradient instead of a solid color',
      ),
    ),
    Polyline(
      points: const [
        LatLng(50.5, -0.09),
        LatLng(51.3498, 6.2603),
        LatLng(53.8566, 2.3522),
      ],
      strokeWidth: 20,
      color: Colors.blue.withOpacity(0.6),
      borderStrokeWidth: 20,
      borderColor: Colors.red.withOpacity(0.4),
      hitValue: (
        title: 'Bordered Line',
        subtitle: 'Solid translucent color fill, with different color outline',
      ),
    ),
    Polyline(
      points: const [
        LatLng(49.1, -0.06),
        LatLng(52.15, -1.4),
        LatLng(55.5, 0.8),
      ],
      strokeWidth: 10,
      color: Colors.yellow,
      borderStrokeWidth: 10,
      borderColor: Colors.blue.withOpacity(0.5),
      hitValue: (
        title: 'BorderedLine 2',
        subtitle: 'Solid translucent color fill, with different color outline',
      ),
    ),
    Polyline(
      points: const [
        LatLng(43.864797, 11.7112939),
        LatLng(36.7948545, 10.2256785),
        LatLng(35.566530, 5.584283),
      ],
      strokeWidth: 10,
      color: Colors.orange,
      pattern: const StrokePattern.dotted(
        spacingFactor: 3,
      ),
      borderStrokeWidth: 8,
      borderColor: Colors.blue.withOpacity(0.5),
      hitValue: (
        title: 'Orange line',
        subtitle: 'Dotted pattern',
      ),
    ),
    // Paris-Nice TGV
    Polyline(
      points: const [
        // Paris
        LatLng(48.8567, 2.3519),
        // Lyon
        LatLng(45.7256, 5.0811),
        // Avignon
        LatLng(43.95, 4.8169),
        // Aix-en-Provence
        LatLng(43.5311, 5.4539),
        // Marseille
        LatLng(43.2964, 5.37),
        // Toulon
        LatLng(43.1222, 5.93),
        // Cannes
        LatLng(43.5514, 7.0128),
        // Antibes
        LatLng(43.5808, 7.1239),
        // Nice
        LatLng(43.6958, 7.2714),
      ],
      strokeWidth: 6,
      color: Colors.green[900]!,
      pattern: StrokePattern.dashed(
        segments: const [50, 20, 30, 20],
      ),
      borderStrokeWidth: 6,
      hitValue: (
        title: 'Green Line',
        subtitle: 'Dashed line',
      ),
    ),
  ];
  late final _polylines =
      Map.fromEntries(_polylinesRaw.map((e) => MapEntry(e.hitValue, e)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polylines')),
      drawer: const MenuDrawer(PolylinePage.route),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(51.5, -0.09),
              initialZoom: 5,
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

                  final hoverLines = hitValues.map((v) {
                    final original = _polylines[v]!;

                    return Polyline<HitValue>(
                      points: original.points,
                      strokeWidth:
                          original.strokeWidth + original.borderStrokeWidth,
                      color: Colors.transparent,
                      borderStrokeWidth: 15,
                      borderColor: Colors.green,
                      useStrokeWidthInMeter: original.useStrokeWidthInMeter,
                    );
                  }).toList();
                  setState(() => _hoverLines = hoverLines);
                },
                onExit: (_) {
                  _prevHitValues = null;
                  setState(() => _hoverLines = null);
                },
                child: GestureDetector(
                  onTap: () => _openTouchedLinesModal(
                    'Tapped',
                    _hitNotifier.value!.hitValues,
                    _hitNotifier.value!.coordinate,
                  ),
                  onLongPress: () => _openTouchedLinesModal(
                    'Long pressed',
                    _hitNotifier.value!.hitValues,
                    _hitNotifier.value!.coordinate,
                  ),
                  onSecondaryTap: () => _openTouchedLinesModal(
                    'Secondary tapped',
                    _hitNotifier.value!.hitValues,
                    _hitNotifier.value!.coordinate,
                  ),
                  child: PolylineLayer(
                    hitNotifier: _hitNotifier,
                    simplificationTolerance: 0,
                    polylines: [..._polylinesRaw, ...?_hoverLines],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openTouchedLinesModal(
    String eventType,
    List<HitValue> tappedLines,
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
              'Tapped Polyline(s)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '$eventType at point: (${coords.latitude.toStringAsFixed(6)}, ${coords.longitude.toStringAsFixed(6)})',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemBuilder: (context, index) {
                  final tappedLineData = tappedLines[index];
                  return ListTile(
                    leading: index == 0
                        ? const Icon(Icons.vertical_align_top)
                        : index == tappedLines.length - 1
                            ? const Icon(Icons.vertical_align_bottom)
                            : const SizedBox.shrink(),
                    title: Text(tappedLineData.title),
                    subtitle: Text(tappedLineData.subtitle),
                    dense: true,
                  );
                },
                itemCount: tappedLines.length,
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
