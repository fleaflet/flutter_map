import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                  'TileLayers can be progromatically reset, disposing of cached files'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                children: <Widget>[
                  MaterialButton(
                    onPressed: _resetTiles,
                    child: const Text('Reset'),
                  ),
                ],
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
      ),
    );
  }
}
