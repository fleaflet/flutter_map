import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

typedef PolylineHitValue = ({String title, String subtitle});

class PolylinePage extends StatefulWidget {
  static const String route = '/polyline';

  const PolylinePage({super.key});

  @override
  State<PolylinePage> createState() => _PolylinePageState();
}

class _PolylinePageState extends State<PolylinePage> {
  final PolylineHitNotifier<PolylineHitValue> _hitNotifier =
      ValueNotifier(null);
  List<PolylineHitValue>? _prevHitValues;
  List<Polyline<PolylineHitValue>>? _hoverLines;

  final _polylinesRaw = <Polyline<PolylineHitValue>>[
    const Polyline(
      points: [
        LatLng(51.5, -0.09),
        LatLng(53.3498, -6.2603),
        LatLng(48.8566, 2.3522),
      ],
      strokeWidth: 8,
      color: Color(0xFF60399E),
      hitValue: (
        title: 'Elizabeth Line',
        subtitle: 'Nothing really special here...',
      ),
    ),
    const Polyline(
      points: [
        LatLng(48.5, -3.09),
        LatLng(47.3498, -9.2603),
        LatLng(43.8566, -1.3522),
      ],
      strokeWidth: 16000,
      color: Colors.pink,
      useStrokeWidthInMeter: true,
      hitValue: (
        title: 'Pink Line',
        subtitle: 'Fixed radius in meters instead of pixels',
      ),
    ),
    const Polyline(
      points: [
        LatLng(55.5, -0.09),
        LatLng(54.3498, -6.2603),
        LatLng(52.8566, 2.3522),
      ],
      strokeWidth: 4,
      gradientColors: [
        Color(0xffE40203),
        Color(0xffFEED00),
        Color(0xff007E2D),
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

  static const double _initialSimplificationTolerance = 1;
  double simplificationTolerance = _initialSimplificationTolerance;

  @override
  void initState() {
    super.initState();
    final random = Random(1234);
    for (int i = 1; i < 300000; i++) {
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
                    simplificationTolerance: null,
                    polylines: [..._polylinesRaw, ...?_hoverLines],
                  ),
                ),
              ),
              PolylineLayer(
                simplificationTolerance: simplificationTolerance == 0
                    ? null
                    : simplificationTolerance,
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

class SimplificationToleranceSlider extends StatefulWidget {
  const SimplificationToleranceSlider({
    super.key,
    required this.initialTolerance,
    required this.onChangedTolerance,
  });

  final double initialTolerance;
  final void Function(double) onChangedTolerance;

  @override
  State<SimplificationToleranceSlider> createState() =>
      _SimplificationToleranceSliderState();
}

class _SimplificationToleranceSliderState
    extends State<SimplificationToleranceSlider> {
  late double _simplificationTolerance = widget.initialTolerance;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
        child: Row(
          children: [
            const Tooltip(
              message: 'Adjust Simplification Tolerance',
              child: Row(
                children: [
                  Icon(Icons.insights),
                  SizedBox(width: 8),
                  Icon(Icons.hdr_strong),
                ],
              ),
            ),
            Expanded(
              child: Slider(
                value: _simplificationTolerance,
                onChanged: (v) {
                  if (_simplificationTolerance == 0 && v != 0) {
                    widget.onChangedTolerance(v);
                  }
                  setState(() => _simplificationTolerance = v);
                },
                onChangeEnd: widget.onChangedTolerance,
                min: 0,
                max: 2.5,
                divisions: 125,
                label: _simplificationTolerance == 0
                    ? 'Disabled'
                    : _simplificationTolerance.toStringAsFixed(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
