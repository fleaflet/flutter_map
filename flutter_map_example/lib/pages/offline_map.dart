import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class OfflineMapPage extends StatelessWidget {
  static const String route = '/offline_map';
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text("Offline Map")),
      drawer: buildDrawer(context, route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Text(
                  "This is an offline map that is showing Anholt Island, Denmark."),
            ),
            new Flexible(
              child: new FlutterMap(
                options: new MapOptions(
                  center: new LatLng(56.704173, 11.543808),
                  minZoom: 12.0,
                  maxZoom: 14.0,
                  zoom: 13.0,
                  swPanBoundary: LatLng(56.6877, 11.5089),
                  nePanBoundary: LatLng(56.7378, 11.6644),
                ),
                layers: [
                  new TileLayerOptions(
                    offlineMode: true,
                    maxZoom: 14.0,
                    urlTemplate: "assets/map/anholt_osmbright/{z}/{x}/{y}.png",
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
