import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class EsriPage extends StatelessWidget {
  static const String route = 'esri';

  const EsriPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Esri')),
      drawer: buildDrawer(context, route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text('Esri'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(45.5231, -122.6765),
                  zoom: 13,
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate:
                        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
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
