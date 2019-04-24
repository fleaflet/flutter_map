import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class CirclePage extends StatelessWidget {
  static const String route = 'circle';

  @override
  Widget build(BuildContext context) {
    var circleMarkers = <CircleMarker>[
      new CircleMarker(
          point: new LatLng(51.5, -0.09),
          color: Colors.blue.withOpacity(0.7),
          useRadiusInMeter: true,
          radius: 2000 // 2000 meters | 2 km
          ),
    ];

    return new Scaffold(
      appBar: new AppBar(title: new Text("Circle")),
      drawer: buildDrawer(context, route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Text("This is a map that is showing (51.5, -0.9)."),
            ),
            new Flexible(
              child: new FlutterMap(
                options: new MapOptions(
                  center: new LatLng(51.5, -0.09),
                  zoom: 11.0,
                ),
                layers: [
                  new TileLayerOptions(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c']),
                  new CircleLayerOptions(circles: circleMarkers)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
