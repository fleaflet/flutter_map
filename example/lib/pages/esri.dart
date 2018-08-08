import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../pages/tap_to_add.dart';
import '../widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class EsriPage extends StatelessWidget {
  static const String route = "esri";

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text("Esri")),
      drawer: buildDrawer(context, TapToAddPage.route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Text("Esri"),
            ),
            new Flexible(
              child: new FlutterMap(
                options: new MapOptions(
                  center: new LatLng(45.5231, -122.6765),
                  zoom: 13.0,
                ),
                layers: [
                  new TileLayerOptions(
                    urlTemplate:
                    "https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}",
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
