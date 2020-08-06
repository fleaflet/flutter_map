import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

class InteractiveTestPage extends StatefulWidget {
  static const String route = 'interactive_test_page';

  @override
  State createState() {
    // TODO: try out InteractiveTestPageState it is using StreamBuilder
    return InteractiveTestPageWithoutBooleansState();
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
            Row(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                MaterialButton(
                  child: Text('Double tap zoom'),
                  color: doubleTapZoom ? Colors.greenAccent : Colors.redAccent,
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
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Center(
                child: FutureBuilder<Null>(
                  future: mapController.onReady,
                  builder:
                      (BuildContext context, AsyncSnapshot<Null> snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Text('No MapEvent fired');
                    }

                    return StreamBuilder<MapEvent>(
                      stream: mapController.mapEventStream,
                      builder: (BuildContext context,
                          AsyncSnapshot<MapEvent> snapshot) {
                        if (snapshot.connectionState == ConnectionState.none ||
                            !snapshot.hasData) {
                          return Text('No MapEvent fired');
                        }

                        return Text(
                          'Current event: ${snapshot.data.runtimeType}\nSource: ${snapshot.data.source}',
                          textAlign: TextAlign.center,
                        );
                      },
                    );
                  },
                ),
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

class InteractiveTestPageWithoutBooleansState
    extends State<InteractiveTestPage> {
  MapController mapController;

  // Enable pinchZoom and doubleTapZoomBy by default
  int flags = InteractiveFlags.pinchZoom | InteractiveFlags.doubleTapZoom;

  // Here is the last moveEvent which is not extends MapEventWithMove
  MapEvent lastMapEvent;

  StreamSubscription<MapEvent> subscription;

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    mapController.onReady.then((_) {
      // at this point we can listen to [mapEventStream]
      // use stream transformer or anything you want
      subscription = mapController.mapEventStream.listen((MapEvent mapEvent) {
        setState(() {
          print(mapEvent);
          if (mapEvent is! MapEventWithMove) {
            lastMapEvent = mapEvent;
          }
        });
      });
    });
  }

  @override
  void dispose() {
    if (subscription != null) {
      subscription.cancel();
    }

    super.dispose();
  }

  void updateFlags(int flag) {
    if (InteractiveFlags.hasFlag(flags, flag)) {
      // remove flag from flags
      flags -= flag;
    } else {
      // add flag to flags
      flags |= flag;
    }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                MaterialButton(
                  child: Text('Move'),
                  color: InteractiveFlags.hasFlag(flags, InteractiveFlags.move)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlags.move);
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Fling'),
                  color: InteractiveFlags.hasFlag(flags, InteractiveFlags.fling)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlags.fling);
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Pinch zoom'),
                  color: InteractiveFlags.hasFlag(
                          flags, InteractiveFlags.pinchZoom)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlags.pinchZoom);
                    });
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                MaterialButton(
                  child: Text('Double tap zoom'),
                  color: InteractiveFlags.hasFlag(
                          flags, InteractiveFlags.doubleTapZoom)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlags.doubleTapZoom);
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Rotate'),
                  color:
                      InteractiveFlags.hasFlag(flags, InteractiveFlags.rotate)
                          ? Colors.greenAccent
                          : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlags.rotate);
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
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Center(
                child: Text(
                  lastMapEvent == null
                      ? 'No MapEvent fired'
                      : 'Current event: ${lastMapEvent.runtimeType}\nSource: ${lastMapEvent.source}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Flexible(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 11.0,
                  interactiveFlags: flags,
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
