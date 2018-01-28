import 'package:flutter/material.dart';
import 'package:leaflet_flutter/leaflet_flutter.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Leaflet example',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text("Leaflet Example"),
        ),
        body: new Center(
          child: new AspectRatio(
            aspectRatio: 1.0,
            child: new Leaflet(
              options: new MapOptions(),
              layers: [
                new TileLayerOptions(
                  urlTemplate: "https://api.tiles.mapbox.com/v4/"
                      "{id}/{z}/{x}/{y}.png?access_token={accessToken}",
                  additionalOptions: {
                    'accessToken':
                        'pk.eyJ1Ijoiam9obnByeWFuIiwiYSI6ImNqY3VyZmlybjExZXoycXZ0bmdldml3Z2EifQ.kLtehVgGf0EnSo-K4h5G2A',
                    'id': 'mapbox.streets',
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
