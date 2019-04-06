import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

class MarkerAnchorPage extends StatefulWidget {
  static const String route = '/marker_anchors';
  @override
  MarkerAnchorPageState createState() {
    return new MarkerAnchorPageState();
  }
}

class MarkerAnchorPageState extends State<MarkerAnchorPage> {
  AnchorPos anchorPos;

  void initState() {
    super.initState();
    anchorPos = AnchorPos.align(AnchorAlign.center);
  }

  void _setAnchorAlignPos(AnchorAlign alignOpt) {
    setState(() {
      anchorPos = AnchorPos.align(alignOpt);
    });
  }

  void _setAnchorExactlyPos(Anchor anchor) {
    setState(() {
      anchorPos = AnchorPos.exactly(anchor);
    });
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
        anchorPos: anchorPos,
      ),
      new Marker(
        width: 80.0,
        height: 80.0,
        point: new LatLng(53.3498, -6.2603),
        builder: (ctx) => new Container(
              child: new FlutterLogo(
                colors: Colors.green,
              ),
            ),
        anchorPos: anchorPos,
      ),
      new Marker(
        width: 80.0,
        height: 80.0,
        point: new LatLng(48.8566, 2.3522),
        builder: (ctx) => new Container(
              child: new FlutterLogo(colors: Colors.purple),
            ),
        anchorPos: anchorPos,
      ),
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
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.left),
                  ),
                  new MaterialButton(
                    child: new Text("Right"),
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.right),
                  ),
                  new MaterialButton(
                    child: new Text("Top"),
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.top),
                  ),
                  new MaterialButton(
                    child: new Text("Bottom"),
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.bottom),
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
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.center),
                  ),
                  new MaterialButton(
                    child: new Text("Custom"),
                    onPressed: () => _setAnchorExactlyPos(Anchor(80.0, 80.0)),
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
