import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class PolygonPage extends StatelessWidget {
  static const String route = '/polygon';

  const PolygonPage({super.key});

  final _notFilledPoints = const [
    LatLng(51.5, -0.09),
    LatLng(53.3498, -6.2603),
    LatLng(48.8566, 2.3522),
  ];
  final _filledPoints = const [
    LatLng(55.5, -0.09),
    LatLng(54.3498, -6.2603),
    LatLng(52.8566, 2.3522),
  ];
  final _filledDotedPoints = const [
    LatLng(46.35, 4.94),
    LatLng(46.22, -0.11),
    LatLng(44.399, 1.76),
  ];
  final _labelPoints = const [
    LatLng(60.16, -9.38),
    LatLng(60.16, -4.16),
    LatLng(61.18, -4.16),
    LatLng(61.18, -9.38),
  ];
  final _labelRotatedPoints = const [
    LatLng(59.77, -10.28),
    LatLng(58.21, -10.28),
    LatLng(58.21, -7.01),
    LatLng(59.77, -7.01),
    LatLng(60.77, -6.01),
  ];
  final _normalHoleOuterPoints = const [
    LatLng(50, -18),
    LatLng(50, -14),
    LatLng(51.5, -12.5),
    LatLng(54, -14),
    LatLng(54, -18),
  ];
  final _brokenHoleOuterPoints = const [
    LatLng(50, -18),
    LatLng(53, -16),
    LatLng(51.5, -12.5),
    LatLng(54, -14),
    LatLng(54, -18),
  ];
  final _holeInnerPoints = const [
    [
      LatLng(52, -17),
      LatLng(52, -16),
      LatLng(51.5, -15.5),
      LatLng(51, -16),
      LatLng(51, -17),
    ],
    [
      LatLng(53.5, -17),
      LatLng(53.5, -16),
      LatLng(53, -15),
      LatLng(52.25, -15),
      LatLng(52.25, -16),
      LatLng(52.75, -17),
    ],
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
              initialCenter: LatLng(51.5, -0.09),
              initialZoom: 5,
            ),
            children: [
              openStreetMapTileLayer,
              PolygonLayer(
                simplificationTolerance: 0,
                polygons: [
                  Polygon(
                    points: _notFilledPoints,
                    borderColor: Colors.red,
                    borderStrokeWidth: 4,
                  ),
                  Polygon(
                    points: _filledPoints,
                    color: Colors.purple,
                    borderColor: Colors.yellow,
                    borderStrokeWidth: 4,
                  ),
                  Polygon(
                    points: _filledDotedPoints,
                    isDotted: true,
                    borderStrokeWidth: 4,
                    borderColor: Colors.lightBlue,
                    color: Colors.yellow,
                  ),
                  Polygon(
                    points: _labelPoints,
                    borderStrokeWidth: 4,
                    borderColor: Colors.purple,
                    label: 'Label!',
                  ),
                  Polygon(
                    points: _labelRotatedPoints,
                    borderStrokeWidth: 4,
                    borderColor: Colors.purple,
                    label: 'Rotated!',
                    rotateLabel: true,
                    labelPlacement: PolygonLabelPlacement.polylabel,
                  ),
                  Polygon(
                    points: _normalHoleOuterPoints
                        .map((latlng) =>
                            LatLng(latlng.latitude, latlng.longitude + 8))
                        .toList(),
                    isDotted: true,
                    holePointsList: _holeInnerPoints
                        .map(
                          (latlngs) => latlngs
                              .map((latlng) =>
                                  LatLng(latlng.latitude, latlng.longitude + 8))
                              .toList(),
                        )
                        .toList(),
                    borderStrokeWidth: 4,
                    borderColor: Colors.orange,
                    color: Colors.orange.withOpacity(0.5),
                    performantRendering: false,
                    label: 'This one is not\nperformantly rendered',
                    rotateLabel: true,
                    labelPlacement: PolygonLabelPlacement.centroid,
                    labelStyle: const TextStyle(color: Colors.black),
                  ),
                  Polygon(
                    points: _brokenHoleOuterPoints
                        .map((latlng) =>
                            LatLng(latlng.latitude - 6, latlng.longitude + 8))
                        .toList(),
                    isDotted: true,
                    holePointsList: _holeInnerPoints
                        .map(
                          (latlngs) => latlngs
                              .map((latlng) => LatLng(
                                  latlng.latitude - 6, latlng.longitude + 8))
                              .toList(),
                        )
                        .toList(),
                    borderStrokeWidth: 4,
                    borderColor: Colors.orange,
                    color: Colors.orange.withOpacity(0.5),
                    performantRendering: false,
                    label: 'This one is not\nperformantly rendered',
                    rotateLabel: true,
                    labelPlacement: PolygonLabelPlacement.centroid,
                    labelStyle: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
              PolygonLayer(
                simplificationTolerance: 0,
                performantRendering: true,
                polygons: [
                  Polygon(
                    points: _normalHoleOuterPoints,
                    holePointsList: _holeInnerPoints,
                    borderStrokeWidth: 4,
                    borderColor: Colors.black,
                    color: Colors.green,
                  ),
                  Polygon(
                    points: _brokenHoleOuterPoints
                        .map((latlng) =>
                            LatLng(latlng.latitude - 6, latlng.longitude))
                        .toList(),
                    holePointsList: _holeInnerPoints
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
}
