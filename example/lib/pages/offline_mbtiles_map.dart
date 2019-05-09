import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

class OfflineMBTilesMapPage extends StatelessWidget {
  static const String route = '/offline_mbtiles_map';

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text("Offline Map (using MBTiles)")),
      drawer: buildDrawer(context, OfflineMBTilesMapPage.route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Text(
                  "This is an offline map of Berlin, Germany using a single MBTiles file. The file was built from the Stamen toner map data (http://maps.stamen.com).\n\n"
                  "(Map tiles by Stamen Design, under CC BY 3.0. Data by OpenStreetMap, under ODbL.)"),
            ),
            new Flexible(
              child: new FlutterMap(
                options: new MapOptions(
                  center: new LatLng(
                    52.516144,
                    13.404938,
                  ),
                  minZoom: 12.0,
                  maxZoom: 14.0,
                  zoom: 12.0,
                  swPanBoundary: LatLng(52.492205, 13.282081),
                  nePanBoundary: LatLng(52.540084, 13.527795),
                ),
                layers: [
                  new TileLayerOptions(
                      tileProvider: MBTilesImageProvider.fromAsset(
                          "assets/berlin.mbtiles"),
                      maxZoom: 14.0,
                      backgroundColor: Colors.white,
                      tms: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
