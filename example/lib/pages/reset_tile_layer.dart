import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class ResetTileLayerPage extends StatefulWidget {
  static const String route = '/reset_tilelayer';

  const ResetTileLayerPage({super.key});

  @override
  ResetTileLayerPageState createState() => ResetTileLayerPageState();
}

class ResetTileLayerPageState extends State<ResetTileLayerPage> {
  final StreamController<void> resetController = StreamController.broadcast();

  static const layer1 = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const layer2 = 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
  bool layerToggle = true;

  void _resetTiles() {
    setState(() {
      layerToggle = !layerToggle;
    });
    resetController.add(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TileLayer Reset')),
      drawer: const MenuDrawer(ResetTileLayerPage.route),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, right: 8, top: 12),
            child: Text(
              'TileLayers can be progromatically reset, disposing of cached '
              'tiles',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: TextButton.icon(
              onPressed: _resetTiles,
              label: const Text('Reset'),
              icon: const Icon(Icons.restart_alt),
            ),
          ),
          Flexible(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(51.5, -0.09),
                initialZoom: 5,
              ),
              children: [
                TileLayer(
                  reset: resetController.stream,
                  urlTemplate: layerToggle ? layer1 : layer2,
                  subdomains: layerToggle ? const [] : const ['a', 'b', 'c'],
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  tileProvider: CancellableNetworkTileProvider(),
                ),
                const MarkerLayer(
                  markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      point: LatLng(51.5, -0.09),
                      child: FlutterLogo(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
