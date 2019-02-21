import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class OverlayImagePage extends StatelessWidget {
  static const String route = 'overlay_image';
  Widget build(BuildContext context) {
    var overlayImages = <OverlayImage>[
      new OverlayImage(
          bounds: LatLngBounds(LatLng(51.5, -0.09), LatLng(48.8566, 2.3522)),
          opacity: 0.8,
          imageProvider: NetworkImage(
              'https://images.pexels.com/photos/231009/pexels-photo-231009.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=300&w=600')),
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
                  zoom: 6.0,
                ),
                layers: [
                  new TileLayerOptions(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c']),
                  new OverlayImageLayerOptions(overlayImages: overlayImages)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
