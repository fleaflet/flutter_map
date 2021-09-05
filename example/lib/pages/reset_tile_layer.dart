import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class ResetTileLayerPage extends StatefulWidget {
  static const String route = '/reset_tilelayer';
  @override
  ResetTileLayerPageState createState() {
    return ResetTileLayerPageState();
  }
}

class ResetTileLayerPageState extends State<ResetTileLayerPage> {
  StreamController<Null> resetController = StreamController.broadcast();

  String layer1 = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  String layer2 = 'http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
  bool layerToggle = true;

  @override
  void initState() {
    super.initState();
  }

  void _resetTiles() {
    setState(() {
      layerToggle = !layerToggle;
    });
    resetController.add(null);
  }

  @override
  Widget build(BuildContext context) {
    var markers = <Marker>[
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(51.5, -0.09),
        builder: (ctx) => Container(
          child: FlutterLogo(),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('TileLayer Reset')),
      drawer: buildDrawer(context, ResetTileLayerPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                  'TileLayers can be progromatically reset, disposing of cached files'),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Wrap(
                children: <Widget>[
                  MaterialButton(
                    onPressed: _resetTiles,
                    child: Text('Reset'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 5.0,
                ),
                layers: [
                  TileLayerOptions(
                      reset: resetController.stream,
                      urlTemplate: layerToggle ? layer1 : layer2,
                      subdomains: ['a', 'b', 'c']),
                  MarkerLayerOptions(markers: markers)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
