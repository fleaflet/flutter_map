import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

class InteractiveTestPage extends StatefulWidget {
  static const String route = 'interactive_test_page';

  @override
  State createState() {
    return _InteractiveTestPageState();
  }
}

class _InteractiveTestPageState extends State<InteractiveTestPage> {
  MapController mapController;

  // Enable pinchZoom and doubleTapZoomBy by default
  int flags = InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom;

  StreamSubscription<MapEvent> subscription;

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    subscription = mapController.mapEventStream.listen(onMapEvent);
  }

  @override
  void dispose() {
    subscription.cancel();

    super.dispose();
  }

  void onMapEvent(MapEvent mapEvent) {
    if (mapEvent is! MapEventMove && mapEvent is! MapEventRotate) {
      // do not flood console with move and rotate events
      print(mapEvent);
    }
  }

  void updateFlags(int flag) {
    if (InteractiveFlag.hasFlag(flags, flag)) {
      // remove flag from flags
      flags &= ~flag;
    } else {
      // add flag to flags
      flags |= flag;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Text('Drag'),
                  color: InteractiveFlag.hasFlag(flags, InteractiveFlag.drag)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.drag);
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Fling'),
                  color: InteractiveFlag.hasFlag(
                          flags, InteractiveFlag.flingAnimation)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.flingAnimation);
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Pinch move'),
                  color:
                      InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchMove)
                          ? Colors.greenAccent
                          : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.pinchMove);
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
                  color: InteractiveFlag.hasFlag(
                          flags, InteractiveFlag.doubleTapZoom)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.doubleTapZoom);
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Rotate'),
                  color: InteractiveFlag.hasFlag(flags, InteractiveFlag.rotate)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.rotate);
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Pinch zoom'),
                  color:
                      InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchZoom)
                          ? Colors.greenAccent
                          : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.pinchZoom);
                    });
                  },
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Center(
                child: StreamBuilder<MapEvent>(
                  stream: mapController.mapEventStream,
                  builder:
                      (BuildContext context, AsyncSnapshot<MapEvent> snapshot) {
                    if (!snapshot.hasData) {
                      return Text(
                        'Current event: none\nSource: none',
                        textAlign: TextAlign.center,
                      );
                    }

                    return Text(
                      'Current event: ${snapshot.data.runtimeType}\nSource: ${snapshot.data.source}',
                      textAlign: TextAlign.center,
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
                  interactiveFlags: flags,
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
