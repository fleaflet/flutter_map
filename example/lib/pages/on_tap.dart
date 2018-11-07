import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class OnTapPage extends StatefulWidget {
  static const String route = 'on_tap';

  @override
  OnTapPageState createState() {
    return new OnTapPageState();
  }
}

class OnTapPageState extends State<OnTapPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  static LatLng london = new LatLng(51.5, -0.09);
  static LatLng paris = new LatLng(48.8566, 2.3522);
  static LatLng dublin = new LatLng(53.3498, -6.2603);

  Widget build(BuildContext context) {
    var markers = <Marker>[
      new Marker(
        width: 80.0,
        height: 80.0,
        point: london,
        builder: (ctx) => new Container(
                child: new GestureDetector(
                  onTap: () => _onTap("Tapped on green FlutterLogo Marker"),
                  child: new FlutterLogo(),
            )),
      ),
      new Marker(
        width: 80.0,
        height: 80.0,
        point: dublin,
        builder: (ctx) => new Container(
                child: new GestureDetector(
                  onTap: () => _onTap("Tapped on green FlutterLogo Marker"),
                  child: new FlutterLogo(
                    colors: Colors.green,
                  ),
                )),
      ),
      new Marker(
        width: 80.0,
        height: 80.0,
        point: paris,
        builder: (ctx) => new Container(
                child: new GestureDetector(
                  onTap: () => _onTap("Tapped on purple FlutterLogo Marker"),
                  child: new FlutterLogo(colors: Colors.purple),
                )),
      ),
    ];

    var points = <LatLng>[
      new LatLng(51.5, -0.09),
      new LatLng(53.3498, -6.2603),
      new LatLng(48.8566, 2.3522),
    ];

    var polylines = <Polyline>[
      new Polyline(
        points: points,
        strokeWidth: 4.0,
        color: Colors.purple,
      ),
    ];


    var points2 = List<LatLng>.from(points.map((point) => new LatLng(
      point.latitude - 2.5, point.longitude)));

    var polygons = <Polygon>[
      new Polygon(
        points: points2,
        color: Colors.green,
        borderColor: Colors.greenAccent,
        borderStrokeWidth: 4.0,
      ),
    ];

    var points3 = List<LatLng>.from(points2.map((point) => new LatLng(
      point.latitude - 2.5, point.longitude)));


    var circles = <CircleMarker>[
      new CircleMarker(
        point: points3[0],
        radius: 30.0,
        color: Colors.yellow,
        borderColor: Colors.yellowAccent,
        borderStrokeWidth: 4.0,
      ),
      new CircleMarker(
        point: points3[1],
        radius: 30.0,
        color: Colors.deepOrange,
        borderColor: Colors.deepOrangeAccent,
        borderStrokeWidth: 4.0,
      ),
    ];


    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(title: new Text("OnTap")),
      drawer: buildDrawer(context, OnTapPage.route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Text("Try tapping on the markers"),
            ),
            new Flexible(
              child: new FlutterMap(
                options: new MapOptions(
                  center: new LatLng(51.5, -0.09),
                  zoom: 5.0,
                  maxZoom: 5.0,
                  minZoom: 3.0,
                ),
                layers: [
                  new TileLayerOptions(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c']),
                  new CircleLayerOptions(
                    circles: circles,
                    onTap: (CircleMarker circle, LatLng point) =>
                    _onTap("Tapped on $circle")
                  ),
                  new PolylineLayerOptions(
                      polylines: polylines,
                      onTap: (Polyline polyline, LatLng point) =>
                          _onTap("Tapped on $polyline")
                  ),
                  new PolygonLayerOptions(
                      polygons: polygons,
                      onTap: (Polygon polygon, LatLng point) =>
                          _onTap("Tapped on $polygon")
                  ),
                  new MarkerLayerOptions(markers: markers),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(String msg) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(msg),
      duration: Duration(seconds: 1),
    ));
  }
}
