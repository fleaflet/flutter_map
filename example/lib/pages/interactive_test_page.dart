import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class InteractiveTestPage extends StatefulWidget {
  static const String route = 'interactive_test_page';

  const InteractiveTestPage({Key? key}) : super(key: key);

  @override
  State createState() {
    return _InteractiveTestPageState();
  }
}

class _InteractiveTestPageState extends State<InteractiveTestPage> {
  late final MapController mapController;

  // Enable pinchZoom and doubleTapZoomBy by default
  int flags = InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom;

  late final StreamSubscription<MapEvent> subscription;

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
      debugPrint(mapEvent.toString());
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
      appBar: AppBar(title: const Text('Test out Interactive flags!')),
      drawer: buildDrawer(context, InteractiveTestPage.route),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                MaterialButton(
                  color: InteractiveFlag.hasFlag(flags, InteractiveFlag.drag)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.drag);
                    });
                  },
                  child: const Text('Drag'),
                ),
                MaterialButton(
                  color: InteractiveFlag.hasFlag(
                          flags, InteractiveFlag.flingAnimation)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.flingAnimation);
                    });
                  },
                  child: const Text('Fling'),
                ),
                MaterialButton(
                  color:
                      InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchMove)
                          ? Colors.greenAccent
                          : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.pinchMove);
                    });
                  },
                  child: const Text('Pinch move'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                MaterialButton(
                  color: InteractiveFlag.hasFlag(
                          flags, InteractiveFlag.doubleTapZoom)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.doubleTapZoom);
                    });
                  },
                  child: const Text('Double tap zoom'),
                ),
                MaterialButton(
                  color: InteractiveFlag.hasFlag(flags, InteractiveFlag.rotate)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.rotate);
                    });
                  },
                  child: const Text('Rotate'),
                ),
                MaterialButton(
                  color:
                      InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchZoom)
                          ? Colors.greenAccent
                          : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.pinchZoom);
                    });
                  },
                  child: const Text('Pinch zoom'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Center(
                child: StreamBuilder<MapEvent>(
                  stream: mapController.mapEventStream,
                  builder:
                      (BuildContext context, AsyncSnapshot<MapEvent> snapshot) {
                    if (!snapshot.hasData) {
                      return const Text(
                        'Current event: none\nSource: none',
                        textAlign: TextAlign.center,
                      );
                    }

                    return Text(
                      'Current event: ${snapshot.data.runtimeType}\nSource: ${snapshot.data!.source}',
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
