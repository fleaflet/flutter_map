import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

class InteractiveTestPage extends StatefulWidget {
  static const String route = 'interactive_test_page';

  @override
  InteractiveTestPageState createState() {
    return InteractiveTestPageState();
  }
}

class InteractiveTestPageState extends State<InteractiveTestPage> {
  MapController mapController;

  bool move = false;
  bool fling = false;
  bool pinchZoom = true;
  bool doubleTapZoom = true;
  bool rotate = false;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
  }

  int _collectInteractiveFlags() {
    var flags = InteractiveFlags.none;
    if (move) {
      flags = flags | InteractiveFlags.move; // use |= operator
    }
    if (fling) {
      flags |= InteractiveFlags.fling;
    }
    if (pinchZoom) {
      flags |= InteractiveFlags.pinchZoom;
    }
    if (doubleTapZoom) {
      flags |= InteractiveFlags.doubleTapZoom;
    }
    if (rotate) {
      flags |= InteractiveFlags.rotate;
    }

    return flags;
  }

  @override
  Widget build(BuildContext context) {
    var circleMarkers = <CircleMarker>[
      CircleMarker(
          point: LatLng(51.5, -0.09),
          color: Colors.blue.withOpacity(0.7),
          borderStrokeWidth: 2,
          useRadiusInMeter: true,
          radius: 2000 // 2000 meters | 2 km
          ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Test out Interactive flags!')),
      drawer: buildDrawer(context, InteractiveTestPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  MaterialButton(
                    child: Text('Move'),
                    color: move ? Colors.greenAccent : Colors.redAccent,
                    onPressed: () {
                      setState(() {
                        move = !move;
                      });
                    },
                  ),
                  MaterialButton(
                    child: Text('Fling'),
                    color: fling ? Colors.greenAccent : Colors.redAccent,
                    onPressed: () {
                      setState(() {
                        fling = !fling;
                      });
                    },
                  ),
                  MaterialButton(
                    child: Text('Pinch zoom'),
                    color: pinchZoom ? Colors.greenAccent : Colors.redAccent,
                    onPressed: () {
                      setState(() {
                        pinchZoom = !pinchZoom;
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  MaterialButton(
                    child: Text('Double tap zoom'),
                    color:
                        doubleTapZoom ? Colors.greenAccent : Colors.redAccent,
                    onPressed: () {
                      setState(() {
                        doubleTapZoom = !doubleTapZoom;
                      });
                    },
                  ),
                  MaterialButton(
                    child: Text('Rotate'),
                    color: rotate ? Colors.greenAccent : Colors.redAccent,
                    onPressed: () {
                      setState(() {
                        rotate = !rotate;
                      });
                    },
                  ),
                  MaterialButton(
                    color: Colors.grey,
                    child: Text('Skew'),
                    onPressed: null,
                  ),
                ],
              ),
            ),
            Flexible(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 11.0,
                  interactiveFlags: _collectInteractiveFlags(),
                ),
                layers: [
                  TileLayerOptions(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c']),
                  CircleLayerOptions(circles: circleMarkers),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
