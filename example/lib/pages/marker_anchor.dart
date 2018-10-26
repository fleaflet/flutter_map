import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class MarkerAnchorPage extends StatefulWidget {
  static const String route = '/marker_anchors';
  @override
  MarkerAnchorPageState createState() {
    return MarkerAnchorPageState();
  }
}

class MarkerAnchorPageState extends State<MarkerAnchorPage> {
  AnchorPos anchorPos;
  Anchor anchorOverride;

  void initState() {
    super.initState();
    anchorPos = AnchorPos.center;
    anchorOverride = null;
  }

  Widget build(BuildContext context) {
    var markers = <Marker>[
      Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(51.5, -0.09),
          builder: (ctx) => Container(
            child: FlutterLogo(),
          ),
          anchor: anchorPos,
          anchorOverride: anchorOverride),
      Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(53.3498, -6.2603),
          builder: (ctx) => Container(
            child: FlutterLogo(
              colors: Colors.green,
            ),
          ),
          anchor: anchorPos,
          anchorOverride: anchorOverride),
      Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(48.8566, 2.3522),
          builder: (ctx) => Container(
            child: FlutterLogo(colors: Colors.purple),
          ),
          anchor: anchorPos,
          anchorOverride: anchorOverride),
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Marker Anchor Points")),
      drawer: buildDrawer(context, MarkerAnchorPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                  "Markers can be anchored to the top, bottom, left or right."),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Row(
                children: <Widget>[
                  MaterialButton(
                    child: Text("Left"),
                    onPressed: () => setState(() {
                      anchorPos = AnchorPos.left;
                      anchorOverride = null;
                    }),
                  ),
                  MaterialButton(
                    child: Text("Right"),
                    onPressed: () => setState(() {
                      anchorPos = AnchorPos.right;
                      anchorOverride = null;
                    }),
                  ),
                  MaterialButton(
                    child: Text("Top"),
                    onPressed: () => setState(() {
                      anchorPos = AnchorPos.top;
                      anchorOverride = null;
                    }),
                  ),
                  MaterialButton(
                    child: Text("Bottom"),
                    onPressed: () => setState(() {
                      anchorPos = AnchorPos.bottom;
                      anchorOverride = null;
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Row(
                children: <Widget>[
                  MaterialButton(
                    child: Text("Center"),
                    onPressed: () => setState(() {
                      anchorPos = AnchorPos.center;
                      anchorOverride = null;
                    }),
                  ),
                  MaterialButton(
                    child: Text("Custom"),
                    onPressed: () => setState(
                          () {
                        anchorOverride = Anchor(80.0, 80.0);
                      },
                    ),
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
                      urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
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