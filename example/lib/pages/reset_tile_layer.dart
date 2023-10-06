import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class ResetTileLayerPage extends StatefulWidget {
  static const String route = '/reset_tilelayer';

  const ResetTileLayerPage({Key? key}) : super(key: key);

  @override
  ResetTileLayerPageState createState() {
    return ResetTileLayerPageState();
  }
}

class ResetTileLayerPageState extends State<ResetTileLayerPage> {
  StreamController<void> resetController = StreamController.broadcast();

  String layer1 = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  String layer2 = 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
  bool layerToggle = true;

  @override
  void initState() {
    super.initState();
  }

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
      drawer: buildDrawer(context, ResetTileLayerPage.route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                  'TileLayers can be progromatically reset, disposing of cached files'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
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
