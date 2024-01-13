import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/simplification_tolerance_slider.dart';
import 'package:latlong2/latlong.dart';

typedef PolylineHitValue = ({String title, String subtitle});

class PolylinePage extends StatefulWidget {
  static const String route = '/polyline';

  const PolylinePage({super.key});

  @override
  State<PolylinePage> createState() => _PolylinePageState();
}

class _PolylinePageState extends State<PolylinePage> {
  final LayerHitNotifier<PolylineHitValue> _hitNotifier = ValueNotifier(null);
  List<PolylineHitValue>? _prevHitValues;
  List<Polyline<PolylineHitValue>>? _hoverLines;

  final _polylinesRaw = <Polyline<PolylineHitValue>>[
    Polyline(
      points: [
        const LatLng(51.5, -0.09),
        const LatLng(53.3498, -6.2603),
        const LatLng(48.8566, 2.3522),
      ],
      strokeWidth: 8,
      color: const Color(0xFF60399E),
      hitValue: (
        title: 'Elizabeth Line',
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
        title: 'BlueRed Line',
        subtitle: 'Solid translucent color fill, with different color outline',
      ),
    ),
    Polyline(
      points: const [
        LatLng(50.2, -0.08),
        LatLng(51.2498, -10.2603),
        LatLng(54.8566, -9.3522),
      ],
      strokeWidth: 20,
      color: Colors.black.withOpacity(0.2),
      borderStrokeWidth: 20,
      borderColor: Colors.white30,
      hitValue: (
        title: 'BlackWhite Line',
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
        title: 'YellowBlue Line',
        subtitle: 'Solid translucent color fill, with different color outline',
      ),
    ),
  ];
  late final _polylines =
      Map.fromEntries(_polylinesRaw.map((e) => MapEntry(e.hitValue, e)));

  final _randomWalk = [const LatLng(44.861294, 13.845086)];

  static const double _initialSimplificationTolerance = 0.5;
  double simplificationTolerance = _initialSimplificationTolerance;

  @override
  void initState() {
    super.initState();
    final random = Random(1234);
    for (int i = 1; i < 200000; i++) {
      final lat = (random.nextDouble() - 0.5) * 0.001;
      final lon = (random.nextDouble() - 0.6) * 0.001;
      _randomWalk.add(
        LatLng(
          _randomWalk[i - 1].latitude + lat,
          _randomWalk[i - 1].longitude + lon,
        ),
      );
    }
  }

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

                    return Polyline<PolylineHitValue>(
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
                    _hitNotifier.value!.point,
                  ),
                  onLongPress: () => _openTouchedLinesModal(
                    'Long pressed',
                    _hitNotifier.value!.hitValues,
                    _hitNotifier.value!.point,
                  ),
                  onSecondaryTap: () => _openTouchedLinesModal(
                    'Secondary tapped',
                    _hitNotifier.value!.hitValues,
                    _hitNotifier.value!.point,
                  ),
                  child: PolylineLayer(
                    hitNotifier: _hitNotifier,
                    simplificationTolerance: 0,
                    polylines: [..._polylinesRaw, ...?_hoverLines],
                  ),
                ),
              ),
              PolylineLayer(
                simplificationTolerance: simplificationTolerance,
                polylines: [
                  Polyline(
                    points: _randomWalk,
                    strokeWidth: 3,
                    color: Colors.deepOrange,
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: SimplificationToleranceSlider(
              initialTolerance: _initialSimplificationTolerance,
              onChangedTolerance: (v) =>
                  setState(() => simplificationTolerance = v),
            ),
          ),
        ],
      ),
    );
  }

  void _openTouchedLinesModal(
    String eventType,
    List<PolylineHitValue> tappedLines,
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
