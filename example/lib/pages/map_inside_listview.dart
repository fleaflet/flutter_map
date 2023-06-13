import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_example/pages/zoombuttons_plugin_option.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class MapInsideListViewPage extends StatelessWidget {
  static const String route = 'map_inside_listview';

  const MapInsideListViewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map inside ListView')),
      drawer: buildDrawer(context, MapInsideListViewPage.route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: ListView(
          scrollDirection: Axis.vertical,
          children: [
            SizedBox(
              height: 300,
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(51.5, -0.09),
                  initialZoom: 5,
                ),
                nonRotatedChildren: const [
                  FlutterMapZoomButtons(
                    minZoom: 4,
                    maxZoom: 19,
                    mini: true,
                    padding: 10,
                    alignment: Alignment.bottomLeft,
                  ),
                ],
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  ),
                ],
              ),
            ),
            const Card(
              child: ListTile(
                  title: Text(
                      'Scrolling inside the map does not scroll the ListView')),
            ),
            const SizedBox(height: 500),
            const Card(child: ListTile(title: Text('look at that scrolling')))
          ],
        ),
      ),
    );
  }
}
