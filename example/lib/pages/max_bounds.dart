import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class MaxBoundsPage extends StatelessWidget {
  static const String route = '/max_bounds';

  const MaxBoundsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Max Bounds edges check')),
      drawer: buildDrawer(context, route),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                  'This is a map that has edges constrained to a latlng bounds.'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(56.704173, 11.543808),
                  zoom: 3.0,
                  maxBounds:
                      LatLngBounds(LatLng(-90, -180.0), LatLng(90.0, 180.0)),
                  screenSize: MediaQuery.of(context).size,
                ),
                layers: [
                  TileLayerOptions(
                    maxZoom: 15.0,
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
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
