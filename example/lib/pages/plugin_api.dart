import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

class PluginPage extends StatelessWidget {
  static const String route = 'plugins';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Plugins')),
      drawer: buildDrawer(context, PluginPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 5.0,
                ),
                layers: [
                  TileLayerWidget(
                    options: TileLayerOptions(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                  ),
                  MyCustomPluginWidget(),
                  DisplayCenterWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyCustomPluginWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 24.0,
      color: Colors.red,
    );

    return Text("I'm a plugin", style: style);
  }
}

class DisplayCenterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access to mapState
    var mapState = MapStateInheritedWidget.of(context).mapState;

    var style = TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 24.0,
        color: Colors.yellow,
        backgroundColor: Colors.black);

    return Center(
      child: Text(
        'Lat=${mapState.center.latitude} Lng=${mapState.center.longitude}',
        style: style,
      ),
    );
  }
}
