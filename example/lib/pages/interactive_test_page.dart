import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class InteractiveTestPage extends StatefulWidget {
  static const String route = 'interactive_test_page';

  const InteractiveTestPage({Key? key}) : super(key: key);

  @override
  State createState() {
    return _InteractiveTestPageState();
  }
}

class _InteractiveTestPageState extends State<InteractiveTestPage> {

  // Enable pinchZoom and doubleTapZoomBy by default
  int flags = InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom;

  MapEvent? _latestEvent;

  @override
  void initState() {
    super.initState();
  }

  void onMapEvent(MapEvent mapEvent) {
    if (mapEvent is! MapEventMove && mapEvent is! MapEventRotate) {
      // do not flood console with move and rotate events
      debugPrint(mapEvent.toString());
    }

    setState(() {
      _latestEvent = mapEvent;
    });
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
        padding: const EdgeInsets.all(8),
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
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Center(
                child: Text(
                      'Current event: ${_latestEvent?.runtimeType ?? "none"}\nSource: ${_latestEvent?.source ?? "none"}',
                      textAlign: TextAlign.center,
                    ),
              ),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  onMapEvent: onMapEvent,
                  center: LatLng(51.5, -0.09),
                  zoom: 11,
                  interactiveFlags: flags,
                ),
                children: [
                  TileLayerWidget(options: TileLayerOptions(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
