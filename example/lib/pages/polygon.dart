import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class PolygonPage extends StatefulWidget {
  static const String route = "polygon";
  @override
  State createState() => PolygonPageState();
}

class PolygonPageState extends State<PolygonPage> {
  String _eventMessage = "Tap on the map and its elements!";

  Widget build(BuildContext context) {
    var pointsA = <LatLng>[
      LatLng(51.5, -0.09),
      LatLng(53.3498, -6.2603),
      LatLng(48.8566, 2.3522),
    ];
    var pointsB = <LatLng>[
      LatLng(53.482761, -2.241135),
      LatLng(52.065709, 4.300589),
      LatLng(53.215497, 6.564996),
    ];
    return Scaffold(
      appBar: AppBar(title: Text("Polygons")),
      drawer: buildDrawer(context, PolygonPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text("Polygons"),
            ),
            Text(
              "$_eventMessage",
              textAlign: TextAlign.center,
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 5.0,
                  onTap: _handleMapTapped,
                  onLongPress: _handleMapLongPressed,
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                  PolygonLayerOptions(
                    polygons: [
                      Polygon(
                        key: Key("zone_a"),
                        points: pointsA,
                        //borderStrokeWidth: 4.0,
                        borderColor: Colors.purple,
                        closeFigure: true,
                        color: Color(
                            0x509C27B0), // Colors.purple with less opacity
                      ),
                      Polygon(
                        key: Key("zone_b"),
                        points: pointsB,
                        borderStrokeWidth: 4.0,
                        borderColor: Colors.red,
                        closeFigure: true,
                        color:
                            Color(0x50F44336), // Colors.red with less opacity
                      ),
                    ],
                    onTap: _handleTap,
                    onLongPress: _handleLongPress,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMapTapped(LatLng location) {
    var message = "Map tapped at ${location.latitude}, ${location.longitude}";
    print(message);
    setState(() {
      this._eventMessage = message;
    });
  }

  void _handleMapLongPressed(LatLng location) {
    var message =
        "Map long pressed at ${location.latitude}, ${location.longitude}";
    print(message);
    setState(() {
      this._eventMessage = message;
    });
  }

  void _handleTap(Polygon polygon, LatLng location) {
    var message = "Tapped on polygon #${polygon.key}. LatLng = $location";
    print(message);
    setState(() {
      this._eventMessage = message;
    });
  }

  void _handleLongPress(Polygon polygon, LatLng location) {
    var message = "Long press on polygon #${polygon.key}. LatLng = $location";
    print(message);
    setState(() {
      this._eventMessage = message;
    });
  }
}
