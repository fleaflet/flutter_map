import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class BundledOfflineMapPage extends StatelessWidget {
  static const String route = '/bundled_offline_map';

  const BundledOfflineMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bundled Offline Map')),
      drawer: const MenuDrawer(route),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(56.704173, 11.543808),
          minZoom: 12,
          maxZoom: 14,
          cameraConstraint: CameraConstraint.containCenter(
            bounds: LatLngBounds(
              const LatLng(56.7378, 11.6644),
              const LatLng(56.6877, 11.5089),
            ),
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
    );
  }
}
