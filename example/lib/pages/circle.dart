import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/drawer.dart';
import 'package:latlong/latlong.dart' hide Circle;

class CirclePage extends StatefulWidget {
  static const String route = "circle";
  @override
  State createState() => CirclePageState();
}

class CirclePageState extends State<CirclePage> {
  String _eventMessage = "Tap on the map and its elements!";

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Circles")),
      drawer: buildDrawer(context, CirclePage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text("Circles"),
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
                  CircleLayerOptions(
                    circles: [
                      CircleMarker(
                        key: Key("zone_a"),
                        center: LatLng(51.5, -0.09),
                        borderStrokeWidth: 4.0,
                        borderColor: Colors.purple,
                        radius: 100000.0,
                        color: Color(
                            0x509C27B0), // Colors.purple with less opacity
                      ),
                      CircleMarker(
                        key: Key("zone_b"),
                        center: LatLng(53.3498, -6.2603),
                        borderStrokeWidth: 4.0,
                        borderColor: Colors.red,
                        radius: 100000.0,
                        color:
                            Color(0x50F44336), // Colors.red with less opacity
                      ),
                      CircleMarker(
                        key: Key("zone_c"),
                        center: LatLng(48.8566, 2.3522),
                        borderStrokeWidth: 4.0,
                        borderColor: Colors.green,
                        radius: 100000.0,
                        color:
                            Color(0x504CAF50), // Colors.green with less opacity
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

  void _handleTap(CircleMarker circle, LatLng location) {
    var message = "Tapped on circle #${circle.key}. LatLng = $location";
    print(message);
    setState(() {
      this._eventMessage = message;
    });
  }

  void _handleLongPress(CircleMarker circle, LatLng location) {
    var message = "Long press on circle #${circle.key}. LatLng = $location";
    print(message);
    setState(() {
      this._eventMessage = message;
    });
  }
}
