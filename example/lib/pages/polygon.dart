import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';

class PolygonPage extends StatelessWidget {
  static const String route = '/polygon';

  const PolygonPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notFilledPoints = <LatLng>[
      const LatLng(51.5, -0.09),
      const LatLng(53.3498, -6.2603),
      const LatLng(48.8566, 2.3522),
    ];

    final filledPoints = <LatLng>[
      const LatLng(55.5, -0.09),
      const LatLng(54.3498, -6.2603),
      const LatLng(52.8566, 2.3522),
    ];

    final notFilledDotedPoints = <LatLng>[
      const LatLng(49.29, -2.57),
      const LatLng(51.46, -6.43),
      const LatLng(49.86, -8.17),
      const LatLng(48.39, -3.49),
    ];

    final filledDotedPoints = <LatLng>[
      const LatLng(46.35, 4.94),
      const LatLng(46.22, -0.11),
      const LatLng(44.399, 1.76),
    ];

    final labelPoints = <LatLng>[
      const LatLng(60.16, -9.38),
      const LatLng(60.16, -4.16),
      const LatLng(61.18, -4.16),
      const LatLng(61.18, -9.38),
    ];

    final labelRotatedPoints = <LatLng>[
      const LatLng(59.77, -10.28),
      const LatLng(58.21, -10.28),
      const LatLng(58.21, -7.01),
      const LatLng(59.77, -7.01),
      const LatLng(60.77, -6.01),
    ];

    final holeOuterPoints = <LatLng>[
      const LatLng(50, -18),
      const LatLng(50, -14),
      const LatLng(54, -14),
      const LatLng(54, -18),
    ];

    final holeInnerPoints = <LatLng>[
      const LatLng(51, -17),
      const LatLng(51, -16),
      const LatLng(52, -16),
      const LatLng(52, -17),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Polygons')),
      drawer: const MenuDrawer(PolygonPage.route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Polygons'),
            ),
            Flexible(
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(51.5, -0.09),
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
                          .map((latlng) =>
                              LatLng(latlng.latitude, latlng.longitude + 8))
                          .toList(),
                      isFilled: false,
                      isDotted: true,
                      holePointsList: [
                        holeInnerPoints
                            .map((latlng) =>
                                LatLng(latlng.latitude, latlng.longitude + 8))
                            .toList()
                      ],
                      borderStrokeWidth: 4,
                      borderColor: Colors.orange,
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
