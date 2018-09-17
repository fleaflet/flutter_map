import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class OnTapPage extends StatefulWidget {
  static const String route = 'on_tap';

  @override
  OnTapPageState createState() => OnTapPageState();
}

class OnTapPageState extends State<OnTapPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static LatLng london = LatLng(51.5, -0.09);
  static LatLng paris = LatLng(48.8566, 2.3522);
  static LatLng dublin = LatLng(53.3498, -6.2603);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text("OnTap")),
      drawer: buildDrawer(context, OnTapPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text("Try tapping on the markers"),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 5.0,
                  maxZoom: 5.0,
                  minZoom: 3.0,
                ),
                layers: [
                  TileLayerOptions(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c']),
                  MarkerLayerOptions(
                    markers: _buildMarkers(),
                    onTap: _handleMarkerTap,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() => [
        Marker(
          width: 80.0,
          height: 80.0,
          point: london,
          builder: (ctx) => FlutterLogo(colors: Colors.blue),
        ),
        Marker(
          width: 80.0,
          height: 80.0,
          point: dublin,
          builder: (ctx) => FlutterLogo(colors: Colors.green),
        ),
        Marker(
          width: 80.0,
          height: 80.0,
          point: paris,
          builder: (ctx) => GestureDetector(
                onTap: () =>
                    showSnackBarMsg("Tapped on purple FlutterLogo Marker"),
                child: FlutterLogo(colors: Colors.purple),
              ),
        ),
      ];

  void _handleMarkerTap(Marker marker) {
    final point = marker.point;
    String city;
    if (point == london) {
      city = "London";
    } else if (point == dublin) {
      city = "Dublin";
    } else if (point == paris) {
      city = "Paris";
    } else {
      city = "unknown";
    }
    showSnackBarMsg("Tapped on $city FlutterLogo Marker");
  }

  void showSnackBarMsg(String text) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}
