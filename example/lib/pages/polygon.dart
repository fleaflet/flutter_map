import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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

  bool _useInvertedFill = false;
  PolygonLabelPlacementCalculator _labelPlacementCalculator =
      const PolygonLabelPlacementCalculator.centroid();

  late var _polygonsRaw = generatePolygons();
  List<Polygon<HitValue>> generatePolygons() => [
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
          label: 'Label!',
          labelPlacementCalculator: _labelPlacementCalculator,
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
          pattern: StrokePattern.dashed(segments: const [50, 20]),
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
          labelPlacementCalculator: _labelPlacementCalculator,
          labelStyle: const TextStyle(color: Colors.black),
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
          labelPlacementCalculator: _labelPlacementCalculator,
          labelStyle: const TextStyle(color: Colors.black),
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
          ]
              .map((latlng) => LatLng(latlng.latitude, latlng.longitude + 8))
              .toList(),
          pattern: const StrokePattern.dotted(),
          holePointsList: [
            const [
              LatLng(52, -9),
              LatLng(52, -8),
              LatLng(51.5, -7.5),
              LatLng(51, -8),
              LatLng(51, -9),
            ],
            const [
              LatLng(53.5, -9),
              LatLng(53.5, -8),
              LatLng(53, -7),
              LatLng(52.25, -7),
              LatLng(52.25, -8),
              LatLng(52.75, -9),
            ],
            const [
              LatLng(52.683614, -8.141285),
              LatLng(51.663083, -8.684529),
              LatLng(51.913924, -7.2193),
            ],
          ],
          borderStrokeWidth: 4,
          borderColor: Colors.orange,
          color: Colors.orange.withAlpha(128),
          label: 'This one is not\nperformantly rendered',
          rotateLabel: true,
          labelPlacementCalculator: _labelPlacementCalculator,
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
              .map(
                  (latlng) => LatLng(latlng.latitude - 6, latlng.longitude + 8))
              .toList(),
          pattern: const StrokePattern.dotted(),
          holePointsList: [
            const [
              LatLng(46, -9),
              LatLng(46, -8),
              LatLng(45.5, -7.5),
              LatLng(45, -8),
              LatLng(45, -9),
            ].reversed.toList(growable: false), // Testing winding consitency
            const [
              LatLng(47.5, -9),
              LatLng(47.5, -8),
              LatLng(47, -7),
              LatLng(46.25, -7),
              LatLng(46.25, -8),
              LatLng(46.75, -9),
            ].reversed.toList(growable: false),
            const [
              LatLng(46.683614, -8.141285),
              LatLng(45.663083, -8.684529),
              LatLng(45.913924, -7.2193),
            ].reversed.toList(growable: false),
          ],
          borderStrokeWidth: 4,
          borderColor: Colors.orange,
          color: Colors.orange.withAlpha(128),
          label: 'This one is not\nperformantly rendered',
          rotateLabel: true,
          labelPlacementCalculator: _labelPlacementCalculator,
          labelStyle: const TextStyle(color: Colors.black),
          hitValue: (
            title: 'Polygon With Hole & Self Intersection',
            subtitle: 'This one still works with performant rendering',
          ),
        ),
        Polygon(
          points: const [
            LatLng(61.861042, 0.946502),
            LatLng(61.861458, 0.949468),
            LatLng(61.861427, 0.949626),
            LatLng(61.859015, 0.951513),
            LatLng(61.858129, 0.952652)
          ],
          holePointsList: [],
          color: Colors.lightGreen.withAlpha(128),
          borderColor: Colors.lightGreen.withAlpha(128),
          borderStrokeWidth: 10,
          hitValue: (
            title: 'Testing opacity treatment (small)',
            subtitle:
                "Holes shouldn't be cut, and colors should be mixed correctly",
          ),
        ),
        Polygon(
          points: const [
            LatLng(61.861042, 0.946502),
            LatLng(61.861458, 0.949468),
            LatLng(61.861427, 0.949626),
            LatLng(61.859015, 0.951513),
            LatLng(61.858129, 0.952652),
            LatLng(61.857633, 0.953214),
            LatLng(61.855842, 0.954683),
            LatLng(61.855769, 0.954692),
            LatLng(61.855679, 0.954565),
            LatLng(61.855417, 0.953926),
            LatLng(61.855268, 0.953431),
            LatLng(61.855173, 0.952443),
            LatLng(61.855161, 0.951147),
            LatLng(61.855222, 0.950822),
            LatLng(61.855928, 0.948422),
            LatLng(61.856365, 0.946638),
            LatLng(61.856456, 0.946586),
            LatLng(61.856787, 0.946656),
            LatLng(61.857578, 0.946675),
            LatLng(61.859338, 0.946453),
            LatLng(61.861042, 0.946502)
          ],
          holePointsList: const [
            [
              LatLng(61.858881, 0.947234),
              LatLng(61.858728, 0.947126),
              LatLng(61.858562, 0.947132),
              LatLng(61.858458, 0.947192),
              LatLng(61.85844, 0.947716),
              LatLng(61.858488, 0.947819),
              LatLng(61.858766, 0.947818),
              LatLng(61.858893, 0.947779),
              LatLng(61.858975, 0.947542),
              LatLng(61.858881, 0.947234)
            ]
          ],
          color: Colors.lightGreen.withAlpha(128),
          borderColor: Colors.lightGreen.withAlpha(128),
          borderStrokeWidth: 10,
          hitValue: (
            title: 'Testing opacity treatment (large)',
            subtitle:
                "Holes shouldn't be cut, and colors should be mixed correctly",
          ),
        ),
        Polygon(
          points: const [
            LatLng(40, 150),
            LatLng(45, 160),
            LatLng(50, 170),
            LatLng(55, 180),
            LatLng(50, -170),
            LatLng(45, -160),
            LatLng(40, -150),
            LatLng(35, -160),
            LatLng(30, -170),
            LatLng(25, -180),
            LatLng(30, 170),
            LatLng(35, 160),
          ],
          holePointsList: const [
            [
              LatLng(45, 175),
              LatLng(45, -175),
              LatLng(35, -175),
              LatLng(35, 175),
            ],
          ],
          color: const Color(0xFFFF0000),
          hitValue: (
            title: 'Big Red Diamond',
            subtitle: 'Across the anti-meridian boundary',
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polygons')),
      drawer: const MenuDrawer(PolygonPage.route),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(51.5, -7),
              initialZoom: 4,
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
                    final original =
                        _polygonsRaw.singleWhere((p) => p.hitValue == v);

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
                    invertedFill:
                        _useInvertedFill ? Colors.pink.withAlpha(170) : null,
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
                      LatLng(51.5, -122),
                      LatLng(50, -123),
                      LatLng(50, -121),
                    ],
                    borderStrokeWidth: 3,
                    borderColor: Colors.red,
                    color: Colors.orange,
                    label: 'Culling tester',
                  ),
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
                    label:
                        'This one is performantly rendered\n& non-interactive',
                  ),
                  Polygon(
                    points: const [
                      LatLng(44, -18),
                      LatLng(47, -16),
                      LatLng(45.5, -12.5),
                      LatLng(48, -14),
                      LatLng(48, -18),
                    ],
                    holePointsList: [
                      const [
                        LatLng(46, -17),
                        LatLng(46, -16),
                        LatLng(45.5, -15.5),
                        LatLng(45, -16),
                        LatLng(45, -17),
                      ],
                      const [
                        LatLng(47.5, -17),
                        LatLng(47.5, -16),
                        LatLng(47, -15),
                        LatLng(46.25, -15),
                        LatLng(46.25, -16),
                        LatLng(46.75, -17),
                      ],
                      const [
                        LatLng(46.683614, -16.141285),
                        LatLng(45.663083, -16.684529),
                        LatLng(45.913924, -15.2193),
                      ].reversed.toList(growable: false),
                    ],
                    borderStrokeWidth: 4,
                    borderColor: Colors.black,
                    color: Colors.green,
                    label:
                        "Performant-rendering doesn't\nhandle malformed polygons",
                  ),
                ],
              ),
              IgnorePointer(
                // Ignore the marker so it doesn't capture the pointer
                // (as the marker is over the pointer)
                child: ValueListenableBuilder(
                  valueListenable: _hitNotifier,
                  builder: (context, value, _) => MarkerLayer(
                    rotate: true,
                    markers: [
                      if (value != null)
                        Marker(
                          height: 22,
                          width: 24,
                          alignment: Alignment.topCenter,
                          point: value.coordinate,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                  color: Colors.black.withAlpha(255 ~/ 3),
                                  offset: const Offset(0, 11),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const Tooltip(
                        message: 'Label Placement',
                        child: Icon(Icons.format_align_center),
                      ),
                      ChoiceChip(
                        label: const Text('Simple Centroid'),
                        selected: _labelPlacementCalculator ==
                            const PolygonLabelPlacementCalculator
                                .simpleCentroid(),
                        shape: const StadiumBorder(),
                        onSelected: (v) {
                          if (v) {
                            setState(() {
                              _labelPlacementCalculator =
                                  const PolygonLabelPlacementCalculator
                                      .simpleCentroid();
                              _polygonsRaw = generatePolygons();
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Centroid'),
                        selected: _labelPlacementCalculator ==
                            const PolygonLabelPlacementCalculator.centroid(),
                        shape: const StadiumBorder(),
                        onSelected: (v) {
                          if (v) {
                            setState(() {
                              _labelPlacementCalculator =
                                  const PolygonLabelPlacementCalculator
                                      .centroid();
                              _polygonsRaw = generatePolygons();
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Polylabel'),
                        selected: _labelPlacementCalculator ==
                            const PolygonLabelPlacementCalculator.polylabel(),
                        shape: const StadiumBorder(),
                        onSelected: (v) {
                          if (v) {
                            setState(() {
                              _labelPlacementCalculator =
                                  const PolygonLabelPlacementCalculator
                                      .polylabel();
                              _polygonsRaw = generatePolygons();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                FittedBox(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kIsWeb ? 16 : 32),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 12, right: 8, top: 4, bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            spacing: 8,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Tooltip(
                                message: 'Use Inverted Fill',
                                child: Icon(Icons.invert_colors),
                              ),
                              Switch.adaptive(
                                value: _useInvertedFill,
                                onChanged: (v) =>
                                    setState(() => _useInvertedFill = v),
                              ),
                            ],
                          ),
                        ),
                        if (kIsWeb)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius:
                                  BorderRadius.circular(kIsWeb ? 16 : 32),
                            ),
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, top: 6, bottom: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 8,
                              children: [
                                const Icon(Icons.warning),
                                const Icon(Icons.web_asset_off),
                                IconButton(
                                  onPressed: () => launchUrl(Uri.parse(
                                    'https://docs.fleaflet.dev/layers/polygon-layer#inverted-filling',
                                  )),
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                        Colors.amber[100]),
                                  ),
                                  icon: const Icon(Icons.open_in_new),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
