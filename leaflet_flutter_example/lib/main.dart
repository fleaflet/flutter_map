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
            child: new Leaflet(),
          ),
        ),
      ),
    );
  }
}
