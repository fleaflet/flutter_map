import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class PolygonPage extends StatelessWidget {
  static const String route = 'polygon';

  const PolygonPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notFilledPoints = <LatLng>[
      LatLng(51.5, -0.09),
      LatLng(53.3498, -6.2603),
      LatLng(48.8566, 2.3522),
    ];

    final filledPoints = <LatLng>[
      LatLng(55.5, -0.09),
      LatLng(54.3498, -6.2603),
      LatLng(52.8566, 2.3522),
    ];

    final notFilledDotedPoints = <LatLng>[
      LatLng(49.29, -2.57),
      LatLng(51.46, -6.43),
      LatLng(49.86, -8.17),
      LatLng(48.39, -3.49),
    ];

    final filledDotedPoints = <LatLng>[
      LatLng(46.35, 4.94),
      LatLng(46.22, -0.11),
      LatLng(44.399, 1.76),
    ];

    final labelPoints = <LatLng>[
      LatLng(60.16, -9.38),
      LatLng(60.16, -4.16),
      LatLng(61.18, -4.16),
      LatLng(61.18, -9.38),
    ];

    final labelRotatedPoints = <LatLng>[
      LatLng(58.21, -10.28),
      LatLng(58.21, -7.01),
      LatLng(59.77, -7.01),
      LatLng(59.77, -10.28),
    ];

    final holeOuterPoints = <LatLng>[
      LatLng(50.0, -18.0),
      LatLng(50.0, -14.0),
      LatLng(54.0, -14.0),
      LatLng(54.0, -18.0),
    ];

    final holeInnerPoints = <LatLng>[
      LatLng(51.0, -17.0),
      LatLng(51.0, -16.0),
      LatLng(52.0, -16.0),
      LatLng(52.0, -17.0),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Polygons')),
      drawer: buildDrawer(context, PolygonPage.route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text('Polygons'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  ),
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
                      borderColor: Colors.purple,
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
                      borderColor: Colors.purple,
                      label: "Label!",
                    ),
                    Polygon(
                      points: labelRotatedPoints,
                      borderStrokeWidth: 4,
                      borderColor: Colors.purple,
                      label: "Rotated!",
                      rotateLabel: true,
                    ),
                    Polygon(
                      points: holeOuterPoints,
                      //holePointsList: [],
                      holePointsList: [holeInnerPoints],
                      borderStrokeWidth: 4,
                      borderColor: Colors.green,
                      color: Colors.pink.withOpacity(0.5),
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
