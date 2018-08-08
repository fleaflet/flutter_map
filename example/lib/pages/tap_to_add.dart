import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

class TapToAddPage extends StatefulWidget {
  static const String route = '/tap';

  State<StatefulWidget> createState() {
    return new TapToAddPageState();
  }
}

class TapToAddPageState extends State<TapToAddPage> {
  List<LatLng> tappedPoints = [];

  Widget build(BuildContext context) {
    var markers = tappedPoints.map((latlng) {
      return new Marker(
        width: 80.0,
        height: 80.0,
        point: latlng,
        builder: (ctx) => new Container(
          child: new FlutterLogo(),
        ),
      );
    }).toList();

    return new Scaffold(
      appBar: new AppBar(title: new Text("Tap to add pins")),
      drawer: buildDrawer(context, TapToAddPage.route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Text("Tap to add pins"),
            ),
            new Flexible(
              child: new FlutterMap(
                options: new MapOptions(
                    center: new LatLng(45.5231, -122.6765),
                    zoom: 13.0,
                    onTap: _handleTap),
                layers: [
                  new TileLayerOptions(
                    urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  ),
                  new MarkerLayerOptions(markers: markers)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(LatLng latlng) {
    setState(() {
      tappedPoints.add(latlng);
    });
  }
}
