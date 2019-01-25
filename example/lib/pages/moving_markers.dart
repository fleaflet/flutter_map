import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class MovingMarkersPage extends StatefulWidget {
  static const String route = '/moving_markers';

  @override
  _MovingMarkersPageState createState() {
    return new _MovingMarkersPageState();
  }
}

class _MovingMarkersPageState extends State<MovingMarkersPage>
    with SingleTickerProviderStateMixin {
  LatLng point;
  Timer _timer;
  AnimationController controller;

  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {});
    });
    controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
  }

  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  Widget build(BuildContext context) {
    var marker = new Marker(
      width: 80.0,
      height: 80.0,
      point: point,
      builder: (ctx) => new Container(
            child: new FlutterLogo(),
          ),
    );

    return new Scaffold(
      appBar: new AppBar(title: new Text("Home")),
      drawer: buildDrawer(context, MovingMarkersPage.route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Text("This is an examples of moving a marker around"),
            ),
            new Flexible(
              child: new FlutterMap(
                options: new MapOptions(
                  center: new LatLng(51.5, -0.09),
                  zoom: 5.0,
                ),
                layers: [
                  new TileLayerOptions(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c']),
                  new MarkerLayerOptions(markers: <Marker>[marker])
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Marker> _markers = [
  new Marker(
    width: 80.0,
    height: 80.0,
    point: new LatLng(53.3498, -6.2603),
    builder: (ctx) => new Container(
          child: new FlutterLogo(
            colors: Colors.green,
          ),
        ),
  ),
  new Marker(
    width: 80.0,
    height: 80.0,
    point: new LatLng(48.8566, 2.3522),
    builder: (ctx) => new Container(
          child: new FlutterLogo(colors: Colors.purple),
        ),
  ),
];
