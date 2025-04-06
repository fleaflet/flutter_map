import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

@immutable
class Epsg3857NoRepeat extends Epsg3857 {
  @override
  bool get replicatesWorldLongitude => false;
}

typedef HitValue = ({String title, String subtitle});

/// Demo of how the new `oneWorld` parameter works on Poly*Layer's.
///
/// cf. https://github.com/fleaflet/flutter_map/issues/2067
class OneWorldOrNotPage extends StatefulWidget {
  static const String route = '/one_world';

  const OneWorldOrNotPage({super.key});

  @override
  State<OneWorldOrNotPage> createState() => _OneWorldOrNotPageState();
}

class _OneWorldOrNotPageState extends State<OneWorldOrNotPage> {
  final LayerHitNotifier<HitValue> _hitNotifier = ValueNotifier(null);

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
      appBar: AppBar(title: const Text('One World - or not')),
      drawer: const MenuDrawer(OneWorldOrNotPage.route),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(0, 0),
              initialZoom: 0,
              crs: Epsg3857NoRepeat(),
            ),
            children: [
              openStreetMapTileLayer,
              PolylineLayer(
                hitNotifier: _hitNotifier,
                simplificationTolerance: 0,
                oneWorld: false,
                polylines: <Polyline<HitValue>>[
                  Polyline(
                    points: _polylinePoints
                        .map((latLng) =>
                            LatLng(latLng.latitude + 25, latLng.longitude))
                        .toList(),
                    strokeWidth: 8,
                    color: const Color(0xFFFF0000),
                    hitValue: (
                      title: 'Red Line',
                      subtitle: 'Across the universe...',
                    ),
                  ),
                ],
              ),
              PolylineLayer(
                hitNotifier: _hitNotifier,
                simplificationTolerance: 0,
                oneWorld: true,
                polylines: <Polyline<HitValue>>[
                  Polyline(
                    points: _polylinePoints
                        .map((latLng) =>
                            LatLng(latLng.latitude + 0, latLng.longitude))
                        .toList(),
                    strokeWidth: 8,
                    color: const Color(0xFF00FF00),
                    hitValue: (
                      title: 'Green Line',
                      subtitle: 'Across the universe...',
                    ),
                  ),
                ],
              ),
              PolygonLayer(
                hitNotifier: _hitNotifier,
                simplificationTolerance: 0,
                oneWorld: false,
                polygons: <Polygon<HitValue>>[
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
                    hitValue: (
                      title: 'Blue Line',
                      subtitle: 'Across the universe...',
                    ),
                  ),
                  Polygon(
                    points: _polygonPoints
                        .map((latLng) =>
                            LatLng(latLng.latitude - 80, latLng.longitude))
                        .toList(),
                    color: const Color(0xFF000000),
                    hitValue: (
                      title: 'Black Line',
                      subtitle: 'Across the universe...',
                    ),
                  ),
                ],
              ),
              PolygonLayer(
                hitNotifier: _hitNotifier,
                simplificationTolerance: 0,
                oneWorld: true,
                polygons: <Polygon<HitValue>>[
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
                    color: const Color(0xFF00FFFF),
                    hitValue: (
                      title: 'Teal Line',
                      subtitle: 'Across the universe...',
                    ),
                  ),
                  Polygon(
                    points: _polygonPoints
                        .map((latLng) =>
                            LatLng(latLng.latitude - 110, latLng.longitude))
                        .toList(),
                    color: const Color(0xFFFFFF00),
                    hitValue: (
                      title: 'Yellow Line',
                      subtitle: 'Across the universe...',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
