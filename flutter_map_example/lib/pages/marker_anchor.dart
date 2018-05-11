import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class MarkerAnchorPage extends StatefulWidget {
  static const String route = '/marker_anchors';
  @override
  MarkerAnchorPageState createState() {
    return new MarkerAnchorPageState();
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
      new Marker(
          width: 80.0,
          height: 80.0,
          point: new LatLng(51.5, -0.09),
          builder: (ctx) => new Container(
            child: new FlutterLogo(),
          ),
          anchor: anchorPos,
          anchorOverride: anchorOverride),
      new Marker(
          width: 80.0,
          height: 80.0,
          point: new LatLng(53.3498, -6.2603),
          builder: (ctx) => new Container(
            child: new FlutterLogo(
              colors: Colors.green,
            ),
          ),
          anchor: anchorPos,
          anchorOverride: anchorOverride),
      new Marker(
          width: 80.0,
          height: 80.0,
          point: new LatLng(48.8566, 2.3522),
          builder: (ctx) => new Container(
            child: new FlutterLogo(colors: Colors.purple),
          ),
          anchor: anchorPos,
          anchorOverride: anchorOverride),
    ];

    return new Scaffold(
      appBar: new AppBar(title: new Text("Marker Anchor Points")),
      drawer: buildDrawer(context, MarkerAnchorPage.route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Text(
                  "Markers can be anchored to the top, bottom, left or right."),
            ),
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Row(
                children: <Widget>[
                  new MaterialButton(
                    child: new Text("Left"),
                    onPressed: () => setState(() {
                      anchorPos = AnchorPos.left;
                      anchorOverride = null;
                    }),
                  ),
                  new MaterialButton(
                    child: new Text("Right"),
                    onPressed: () => setState(() {
                      anchorPos = AnchorPos.right;
                      anchorOverride = null;
                    }),
                  ),
                  new MaterialButton(
                    child: new Text("Top"),
                    onPressed: () => setState(() {
                      anchorPos = AnchorPos.top;
                      anchorOverride = null;
                    }),
                  ),
                  new MaterialButton(
                    child: new Text("Bottom"),
                    onPressed: () => setState(() {
                      anchorPos = AnchorPos.bottom;
                      anchorOverride = null;
                    }),
                  ),
                ],
              ),
            ),
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Row(
                children: <Widget>[
                  new MaterialButton(
                    child: new Text("Center"),
                    onPressed: () => setState(() {
                      anchorPos = AnchorPos.center;
                      anchorOverride = null;
                    }),
                  ),
                  new MaterialButton(
                    child: new Text("Custom"),
                    onPressed: () => setState(
                          () {
                        anchorOverride = new Anchor(80.0, 80.0);
                      },
                    ),
                  ),
                ],
              ),
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
                  new MarkerLayerOptions(markers: markers)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}