import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class QuadraticCurvePage extends StatelessWidget {
  static const String route = 'quadratic_curve';

  const QuadraticCurvePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final curveMarkers = <QuadraticCurveMarker>[
      QuadraticCurveMarker(
        startPoint: LatLng(51.5, -0.09),
        endPoint: LatLng(53.3498, -6.2603),
        handlePoint: LatLng(55.953251, -3.188267),
      ),
      QuadraticCurveMarker(
        strokeWidth: 3,
        color: Colors.deepPurpleAccent,
        startPoint: LatLng(51.5, -0.09),
        endPoint: LatLng(53.3498, -6.2603),
        handlePoint: LatLng(53.953251, -4.188267),
      )
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Quadratic Curve')),
      drawer: buildDrawer(context, route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text('This is a map that is showing (51.5, -0.9).'),
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
                  QuadraticCurveLayer(
                    curves: curveMarkers,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
