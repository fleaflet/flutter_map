import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

@immutable
class Epsg3857NoRepeat extends Epsg3857 {
  const Epsg3857NoRepeat();

  @override
  bool get replicatesWorldLongitude => false;
}

/// Demo of how the new `drawInSingleWorld` parameter works on Poly*Layer's.
///
/// cf. https://github.com/fleaflet/flutter_map/issues/2067
class SingleWorldPolysPage extends StatefulWidget {
  static const String route = '/single_world_polys';

  const SingleWorldPolysPage({super.key});

  @override
  State<SingleWorldPolysPage> createState() => _SingleWorldPolysPageState();
}

class _SingleWorldPolysPageState extends State<SingleWorldPolysPage> {
  bool _repeatLongitudes = false;

  static const _polylinePoints = [
    LatLng(40, 150),
    LatLng(45, 160),
    LatLng(50, 170),
    LatLng(55, 180),
    LatLng(50, -170),
    LatLng(45, -160),
    LatLng(40, -150),
  ];

  static const _polygonPoints = [
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
  ];

  static const _polygonHolePoints = [
    LatLng(45, 175),
    LatLng(45, -175),
    LatLng(35, -175),
    LatLng(35, 175),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Single World Polys')),
      drawer: const MenuDrawer(SingleWorldPolysPage.route),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(0, 0),
              initialZoom: 0,
              crs: _repeatLongitudes
                  ? const Epsg3857()
                  : const Epsg3857NoRepeat(),
            ),
            children: [
              openStreetMapTileLayer,
              PolygonLayer(
                simplificationTolerance: 0,
                drawInSingleWorld: false,
                polygons: [
                  Polygon(
                    points: _polygonPoints
                        .map((latLng) =>
                            LatLng(latLng.latitude - 20, latLng.longitude))
                        .toList(),
                    holePointsList: [
                      _polygonHolePoints
                          .map((latLng) =>
                              LatLng(latLng.latitude - 20, latLng.longitude))
                          .toList(),
                    ],
                    color: const Color(0xFF0000FF),
                    borderColor: Colors.purple,
                    borderStrokeWidth: 6,
                    pattern: const StrokePattern.dotted(),
                  ),
                  Polygon(
                    points: _polygonPoints
                        .map((latLng) =>
                            LatLng(latLng.latitude - 80, latLng.longitude))
                        .toList(),
                    color: const Color(0xFF000000),
                  ),
                ],
              ),
              PolygonLayer(
                simplificationTolerance: 0,
                drawInSingleWorld: true,
                polygons: [
                  Polygon(
                    points: _polygonPoints
                        .map((latLng) =>
                            LatLng(latLng.latitude - 55, latLng.longitude))
                        .toList(),
                    holePointsList: [
                      _polygonHolePoints
                          .map((latLng) =>
                              LatLng(latLng.latitude - 55, latLng.longitude))
                          .toList(),
                    ],
                    color: const Color(0xFF0000FF),
                    borderColor: Colors.purple,
                    borderStrokeWidth: 6,
                    pattern: const StrokePattern.dotted(),
                  ),
                  Polygon(
                    points: _polygonPoints
                        .map((latLng) =>
                            LatLng(latLng.latitude - 110, latLng.longitude))
                        .toList(),
                    color: const Color(0xFF000000),
                  ),
                ],
              ),
              PolylineLayer(
                simplificationTolerance: 0,
                drawInSingleWorld: false,
                polylines: [
                  Polyline(
                    points: _polylinePoints
                        .map((latLng) =>
                            LatLng(latLng.latitude + 25, latLng.longitude))
                        .toList(),
                    strokeWidth: 8,
                    color: const Color(0xFFFF0000),
                    pattern: const StrokePattern.dotted(),
                  ),
                  Polyline(
                    points: const [
                      LatLng(-80, 150),
                      LatLng(-80, -170),
                      LatLng(-75, -170),
                      LatLng(-75, 150),
                      LatLng(-80, 150),
                    ],
                    strokeWidth: 8,
                    color: Colors.yellow,
                  ),
                ],
              ),
              PolylineLayer(
                simplificationTolerance: 0,
                drawInSingleWorld: true,
                polylines: [
                  Polyline(
                    points: _polylinePoints
                        .map((latLng) =>
                            LatLng(latLng.latitude + 0, latLng.longitude))
                        .toList(),
                    strokeWidth: 8,
                    color: Colors.red,
                    pattern: StrokePattern.dashed(segments: [50, 20]),
                  ),
                  Polyline(
                    points: const [
                      LatLng(80, 150),
                      LatLng(80, -170),
                      LatLng(75, -170),
                      LatLng(75, 150),
                      LatLng(80, 150),
                    ],
                    strokeWidth: 8,
                    color: Colors.yellow,
                  ),
                ],
              ), /*PolygonLayer(
                drawInSingleWorld: true,
                polygons: [
                  Polygon(
                    points: [
                      const LatLng(90, -180),
                      const LatLng(90, 180),
                      const LatLng(-90, 180),
                      const LatLng(-90, -180),
                    ],
                    color: Colors.amber,
                    borderColor: Colors.black,
                    borderStrokeWidth: 5,
                    holePointsList: [
                      [
                        LatLng(46, -9),
                        LatLng(46, -8),
                        LatLng(45.5, -7.5),
                        LatLng(45, -8),
                        LatLng(45, -9),
                      ]
                    ],
                  ),
                ],
              ),*/
            ],
          ),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16,
              ),
              margin: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  const Tooltip(
                    message: 'Prevent unbounded horizontal scrolling',
                    child: Icon(
                      Icons.screen_lock_landscape,
                      size: 32,
                    ),
                  ),
                  Switch.adaptive(
                    value: !_repeatLongitudes,
                    onChanged: (v) => setState(() => _repeatLongitudes = !v),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
