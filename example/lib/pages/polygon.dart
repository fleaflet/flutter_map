import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

typedef HitValue = ({String title, String subtitle});

class PolygonPage extends StatefulWidget {
  static const String route = '/polygon';

  const PolygonPage({super.key});

  @override
  State<PolygonPage> createState() => _PolygonPageState();
}

class _PolygonPageState extends State<PolygonPage> {
  final LayerHitNotifier<HitValue> _hitNotifier = ValueNotifier(null);
  List<HitValue>? _prevHitValues;
  List<Polygon<HitValue>>? _hoverGons;

  final _polygonsRaw = <Polygon<HitValue>>[
    Polygon(
      points: const [
        LatLng(51.5, -0.09),
        LatLng(53.3498, -6.2603),
        LatLng(48.8566, 2.3522),
      ],
      borderColor: Colors.red,
      borderStrokeWidth: 4,
      hitValue: (
        title: 'Basic Unfilled Polygon',
        subtitle: 'Nothing really special here...',
      ),
    ),
    Polygon(
      points: const [
        LatLng(55.5, -0.09),
        LatLng(54.3498, -6.2603),
        LatLng(52.8566, 2.3522),
      ],
      color: Colors.purple,
      borderColor: Colors.yellow,
      borderStrokeWidth: 4,
      hitValue: (
        title: 'Basic Filled Polygon',
        subtitle: 'Nothing really special here...',
      ),
    ),
    Polygon(
      points: const [
        LatLng(46.35, 4.94),
        LatLng(46.22, -0.11),
        LatLng(44.399, 1.76),
      ],
      pattern: PolylinePattern.dashed(segments: const [50, 20]),
      borderStrokeWidth: 4,
      borderColor: Colors.lightBlue,
      color: Colors.yellow,
      hitValue: (
        title: 'Polygon With Dashed Borders',
        subtitle: '...',
      ),
    ),
    Polygon(
      points: const [
        LatLng(60.16, -9.38),
        LatLng(60.16, -4.16),
        LatLng(61.18, -4.16),
        LatLng(61.18, -9.38),
      ],
      borderStrokeWidth: 4,
      borderColor: Colors.purple,
      label: 'Label!',
      hitValue: (
        title: 'Polygon With Label',
        subtitle: 'This is a very descriptive label!',
      ),
    ),
    Polygon(
      points: const [
        LatLng(59.77, -10.28),
        LatLng(58.21, -10.28),
        LatLng(58.21, -7.01),
        LatLng(59.77, -7.01),
        LatLng(60.77, -6.01),
      ],
      borderStrokeWidth: 4,
      borderColor: Colors.purple,
      label: 'Rotated!',
      rotateLabel: true,
      labelPlacement: PolygonLabelPlacement.polylabel,
      hitValue: (
        title: 'Polygon With Rotated Label',
        subtitle: "Now you don't have to turn your head so much",
      ),
    ),
    Polygon(
      points: const [
        LatLng(50, -18),
        LatLng(50, -14),
        LatLng(51.5, -12.5),
        LatLng(54, -14),
        LatLng(54, -18),
      ].map((latlng) => LatLng(latlng.latitude, latlng.longitude + 8)).toList(),
      pattern: const PolylinePattern.dotted(),
      holePointsList: [
        const [
          LatLng(52, -17),
          LatLng(52, -16),
          LatLng(51.5, -15.5),
          LatLng(51, -16),
          LatLng(51, -17),
        ],
        const [
          LatLng(53.5, -17),
          LatLng(53.5, -16),
          LatLng(53, -15),
          LatLng(52.25, -15),
          LatLng(52.25, -16),
          LatLng(52.75, -17),
        ],
      ]
          .map(
            (latlngs) => latlngs
                .map((latlng) => LatLng(latlng.latitude, latlng.longitude + 8))
                .toList(),
          )
          .toList(),
      borderStrokeWidth: 4,
      borderColor: Colors.orange,
      color: Colors.orange.withOpacity(0.5),
      label: 'This one is not\nperformantly rendered',
      rotateLabel: true,
      labelPlacement: PolygonLabelPlacement.centroid,
      labelStyle: const TextStyle(color: Colors.black),
      hitValue: (
        title: 'Polygon With Hole',
        subtitle: 'A bit like Swiss cheese maybe?',
      ),
    ),
    Polygon(
      points: const [
        LatLng(50, -18),
        LatLng(53, -16),
        LatLng(51.5, -12.5),
        LatLng(54, -14),
        LatLng(54, -18),
      ]
          .map((latlng) => LatLng(latlng.latitude - 6, latlng.longitude + 8))
          .toList(),
      pattern: const PolylinePattern.dotted(),
      holePointsList: [
        const [
          LatLng(52, -17),
          LatLng(52, -16),
          LatLng(51.5, -15.5),
          LatLng(51, -16),
          LatLng(51, -17),
        ],
        const [
          LatLng(53.5, -17),
          LatLng(53.5, -16),
          LatLng(53, -15),
          LatLng(52.25, -15),
          LatLng(52.25, -16),
          LatLng(52.75, -17),
        ],
      ]
          .map(
            (latlngs) => latlngs
                .map((latlng) =>
                    LatLng(latlng.latitude - 6, latlng.longitude + 8))
                .toList(),
          )
          .toList(),
      borderStrokeWidth: 4,
      borderColor: Colors.orange,
      color: Colors.orange.withOpacity(0.5),
      label: 'This one is not\nperformantly rendered',
      rotateLabel: true,
      labelPlacement: PolygonLabelPlacement.centroid,
      labelStyle: const TextStyle(color: Colors.black),
      hitValue: (
        title: 'Polygon With Hole & Self Intersection',
        subtitle: 'This one still works with performant rendering',
      ),
    ),
  ];
  late final _polygons =
      Map.fromEntries(_polygonsRaw.map((e) => MapEntry(e.hitValue, e)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polygons')),
      drawer: const MenuDrawer(PolygonPage.route),
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
                    final original = _polygons[v]!;

                    return Polygon<HitValue>(
                      points: original.points,
                      holePointsList: original.holePointsList,
                      color: Colors.transparent,
                      borderStrokeWidth: 15,
                      borderColor: Colors.green,
                      disableHolesBorder: original.disableHolesBorder,
                    );
                  }).toList();
                  setState(() => _hoverGons = hoverLines);
                },
                onExit: (_) {
                  _prevHitValues = null;
                  setState(() => _hoverGons = null);
                },
                child: GestureDetector(
                  onTap: () => _openTouchedGonsModal(
                    'Tapped',
                    _hitNotifier.value!.hitValues,
                    _hitNotifier.value!.coordinate,
                  ),
                  onLongPress: () => _openTouchedGonsModal(
                    'Long pressed',
                    _hitNotifier.value!.hitValues,
                    _hitNotifier.value!.coordinate,
                  ),
                  onSecondaryTap: () => _openTouchedGonsModal(
                    'Secondary tapped',
                    _hitNotifier.value!.hitValues,
                    _hitNotifier.value!.coordinate,
                  ),
                  child: PolygonLayer(
                    hitNotifier: _hitNotifier,
                    simplificationTolerance: 0,
                    polygons: [..._polygonsRaw, ...?_hoverGons],
                  ),
                ),
              ),
              PolygonLayer(
                simplificationTolerance: 0,
                useAltRendering: true,
                polygons: [
                  Polygon(
                    points: const [
                      LatLng(50, -18),
                      LatLng(50, -14),
                      LatLng(51.5, -12.5),
                      LatLng(54, -14),
                      LatLng(54, -18),
                    ],
                    holePointsList: [
                      const [
                        LatLng(52, -17),
                        LatLng(52, -16),
                        LatLng(51.5, -15.5),
                        LatLng(51, -16),
                        LatLng(51, -17),
                      ],
                      const [
                        LatLng(53.5, -17),
                        LatLng(53.5, -16),
                        LatLng(53, -15),
                        LatLng(52.25, -15),
                        LatLng(52.25, -16),
                        LatLng(52.75, -17),
                      ],
                    ],
                    borderStrokeWidth: 4,
                    borderColor: Colors.black,
                    color: Colors.green,
                  ),
                  Polygon(
                    points: const [
                      LatLng(50, -18),
                      LatLng(53, -16),
                      LatLng(51.5, -12.5),
                      LatLng(54, -14),
                      LatLng(54, -18),
                    ]
                        .map((latlng) =>
                            LatLng(latlng.latitude - 6, latlng.longitude))
                        .toList(),
                    holePointsList: [
                      const [
                        LatLng(52, -17),
                        LatLng(52, -16),
                        LatLng(51.5, -15.5),
                        LatLng(51, -16),
                        LatLng(51, -17),
                      ],
                      const [
                        LatLng(53.5, -17),
                        LatLng(53.5, -16),
                        LatLng(53, -15),
                        LatLng(52.25, -15),
                        LatLng(52.25, -16),
                        LatLng(52.75, -17),
                      ],
                    ]
                        .map(
                          (latlngs) => latlngs
                              .map((latlng) =>
                                  LatLng(latlng.latitude - 6, latlng.longitude))
                              .toList(),
                        )
                        .toList(),
                    borderStrokeWidth: 4,
                    borderColor: Colors.black,
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openTouchedGonsModal(
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
              'Tapped Polygon(s)',
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
