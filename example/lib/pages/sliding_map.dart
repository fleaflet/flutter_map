import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class SlidingMapPage extends StatelessWidget {
  static const String route = '/sliding_map';
  static const northEast = LatLng(56.7378, 11.6644);
  static const southWest = LatLng(56.6877, 11.5089);

  const SlidingMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sliding Map')),
      drawer: const MenuDrawer(route),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'This is a map that can be panned smoothly when the '
              'boundaries are reached.',
            ),
          ),
          Flexible(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(56.704173, 11.543808),
                minZoom: 12,
                maxZoom: 14,
                initialZoom: 13,
                cameraConstraint: CameraConstraint.containCenter(
                  bounds: LatLngBounds(northEast, southWest),
                ),
              ),
              children: [
                TileLayer(
                  tileProvider: AssetTileProvider(),
                  maxZoom: 14,
                  urlTemplate: 'assets/map/anholt_osmbright/{z}/{x}/{y}.png',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
