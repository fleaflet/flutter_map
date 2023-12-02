import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';

class PolygonPage extends StatelessWidget {
  static const String route = '/polygon';

  const PolygonPage({super.key});

  @override
  Widget build(BuildContext context) {
    const notFilledPoints = <LatLng>[
      (lat: 51.5, lon: -0.09),
      (lat: 53.3498, lon: -6.2603),
      (lat: 48.8566, lon: 2.3522),
    ];

    final filledPoints = <LatLng>[
      (lat: 55.5, lon: -0.09),
      (lat: 54.3498, lon: -6.2603),
      (lat: 52.8566, lon: 2.3522),
    ];

    final notFilledDotedPoints = <LatLng>[
      const (lat: 49.29, lon: 2.57),
      const (lat: 51.46, lon: 6.43),
      const (lat: 49.86, lon: 8.17),
      const (lat: 48.39, lon: 3.49),
    ];

    final filledDotedPoints = <LatLng>[
      const (lat: 46.35, lon: 4.94),
      const (lat: 46.22, lon: 0.11),
      const (lat: 44.399, lon: 1.76),
    ];

    final labelPoints = <LatLng>[
      const (lat: 60.16, lon: 9.38),
      const (lat: 60.16, lon: 4.16),
      const (lat: 61.18, lon: 4.16),
      const (lat: 61.18, lon: 9.38),
    ];

    final labelRotatedPoints = <LatLng>[
      const (lat: 59.77, lon: 10.28),
      const (lat: 58.21, lon: 10.28),
      const (lat: 58.21, lon: 7.01),
      const (lat: 59.77, lon: 7.01),
      const (lat: 60.77, lon: 6.01),
    ];

    final holeOuterPoints = <LatLng>[
      const (lat: 50, lon: 18),
      const (lat: 50, lon: 14),
      const (lat: 54, lon: 14),
      const (lat: 54, lon: 18),
    ];

    final holeInnerPoints = <LatLng>[
      const (lat: 51, lon: 17),
      const (lat: 51, lon: 16),
      const (lat: 52, lon: 16),
      const (lat: 52, lon: 17),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Polygons')),
      drawer: const MenuDrawer(PolygonPage.route),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: (lat: 51.5, lon: 0.09),
          initialZoom: 5,
        ),
        children: [
          openStreetMapTileLayer,
          PolygonLayer(polygons: [
            Polygon(
              points: notFilledPoints,
              isFilled: false, // By default it's false
              borderColor: Colors.red,
              borderStrokeWidth: 4,
            ),
            Polygon(
              points: filledPoints,
              isFilled: true,
              color: Colors.purple,
              borderColor: Colors.yellow,
              borderStrokeWidth: 4,
            ),
            Polygon(
              points: notFilledDotedPoints,
              isFilled: false,
              isDotted: true,
              borderColor: Colors.green,
              borderStrokeWidth: 4,
              color: Colors.yellow,
            ),
            Polygon(
              points: filledDotedPoints,
              isFilled: true,
              isDotted: true,
              borderStrokeWidth: 4,
              borderColor: Colors.lightBlue,
              color: Colors.yellow,
            ),
            Polygon(
              points: labelPoints,
              borderStrokeWidth: 4,
              isFilled: false,
              color: Colors.pink,
              borderColor: Colors.purple,
              label: 'Label!',
            ),
            Polygon(
              points: labelRotatedPoints,
              borderStrokeWidth: 4,
              borderColor: Colors.purple,
              label: 'Rotated!',
              rotateLabel: true,
              labelPlacement: PolygonLabelPlacement.polylabel,
            ),
            Polygon(
              points: holeOuterPoints,
              isFilled: true,
              holePointsList: [holeInnerPoints],
              borderStrokeWidth: 4,
              borderColor: Colors.green,
              color: Colors.pink.withOpacity(0.5),
            ),
            Polygon(
              points: holeOuterPoints
                  .map((latlng) => (lat: latlng.lat, lon: latlng.lon + 8))
                  .toList(),
              isFilled: false,
              isDotted: true,
              holePointsList: [
                holeInnerPoints
                    .map((latlng) => (lat: latlng.lat, lon: latlng.lon + 8))
                    .toList()
              ],
              borderStrokeWidth: 4,
              borderColor: Colors.orange,
            ),
          ]),
        ],
      ),
    );
  }
}
