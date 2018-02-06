import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Map Example',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text("Leaflet Example"),
        ),
        body: new Center(
          child: new Padding(
            padding: new EdgeInsets.all(8.0),
            child: new FlutterMap(
              options: new MapOptions(
                center: new LatLng(51.5, -0.09),
                zoom: 13.0,
              ),
              layers: [
                new TileLayerOptions(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),
                new MarkerLayerOptions(
                  markers: [
                    new Marker(
                      width: 80.0,
                      height: 80.0,
                      point: new LatLng(51.5, -0.09),
                      builder: (ctx) => new Container(
                            child: new FlutterLogo(),
                          ),
                    ),
                    new Marker(
                      width: 80.0,
                      height: 80.0,
                      point: new LatLng(51.51, -0.10),
                      builder: (ctx) => new Container(
                            child: new FlutterLogo(
                              colors: Colors.green,
                            ),
                          ),
                    ),
                    new Marker(
                      width: 80.0,
                      height: 80.0,
                      point: new LatLng(51.52, -0.08),
                      builder: (ctx) => new Container(
                            child: new FlutterLogo(colors: Colors.purple),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
