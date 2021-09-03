import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import '../pages/zoombuttons_plugin_option.dart';
import '../widgets/drawer.dart';

class MapInsideListViewPage extends StatelessWidget {
  static const String route = 'map_inside_listview';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map inside ListView')),
      drawer: buildDrawer(context, MapInsideListViewPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: ListView(
          scrollDirection: Axis.vertical,
          children: [
            Container(
              height: 300,
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 5.0,
                  plugins: [
                    ZoomButtonsPlugin(),
                  ],
                ),
                layers: [
                  ZoomButtonsPluginOption(
                    minZoom: 4,
                    maxZoom: 19,
                    mini: true,
                    padding: 10,
                    alignment: Alignment.bottomLeft,
                  )
                ],
                children: <Widget>[
                  TileLayerWidget(
                    options: TileLayerOptions(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                  ),
                ],
              ),
            ),
            Card(
              child: ListTile(
                  title: Text(
                      'Scrolling inside the map does not scroll the ListView')),
            ),
            SizedBox(height: 500),
            Card(child: ListTile(title: Text('look at that scrolling')))
          ],
        ),
      ),
    );
  }
}
