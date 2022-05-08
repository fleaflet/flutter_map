import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class SlidingMapPage extends StatelessWidget {
  static const String route = '/sliding_map';

  const SlidingMapPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sliding Map')),
      drawer: buildDrawer(context, route),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                  'This is a map that can be panned smoothly when the boundaries are reached.'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(56.704173, 11.543808),
                  minZoom: 12.0,
                  maxZoom: 14.0,
                  zoom: 13.0,
                  swPanBoundary: LatLng(56.6877, 11.5089),
                  nePanBoundary: LatLng(56.7378, 11.6644),
                  slideOnBoundaries: true,
                  screenSize: MediaQuery.of(context).size,
                ),
                layers: [
                  TileLayerOptions(
                    tileProvider: const AssetTileProvider(),
                    maxZoom: 14.0,
                    urlTemplate: 'assets/map/anholt_osmbright/{z}/{x}/{y}.png',
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
