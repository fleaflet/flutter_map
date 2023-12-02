import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class EPSG4326Page extends StatelessWidget {
  static const String route = '/crs_epsg4326';

  const EPSG4326Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EPSG4326')),
      drawer: const MenuDrawer(route),
      body: FlutterMap(
        options: const MapOptions(
          minZoom: 0,
          crs: Epsg4326(),
          initialCenter: LatLng(0, 0),
          initialZoom: 0,
        ),
        children: [
          TileLayer(
            wmsOptions: WMSTileLayerOptions(
              crs: const Epsg4326(),
              baseUrl: 'https://ows.mundialis.de/services/service?',
              layers: const ['TOPO-OSM-WMS'],
            ),
            userAgentPackageName: 'dev.fleaflet.flutter_map.example',
          ),
        ],
      ),
    );
  }
}
