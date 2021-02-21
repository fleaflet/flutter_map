import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

/// On this page, [MAX_MARKERS_COUNT] markers are randomly generated
/// across europe, and then you can limit them with a slider
///
/// This way, you can test how map performs under a lot of markers
class ManyMarkersPage extends StatefulWidget {
  static const String route = '/many_markers';

  @override
  _ManyMarkersPageState createState() => _ManyMarkersPageState();
}

class _ManyMarkersPageState extends State<ManyMarkersPage> {
  static const MAX_MARKERS_COUNT = 5000;

  double doubleInRange(Random source, num start, num end) =>
      source.nextDouble() * (end - start) + start;
  List<Marker> allMarkers = [];

  int _sliderVal = MAX_MARKERS_COUNT ~/ 10;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      var r = Random();
      for (var x = 0; x < MAX_MARKERS_COUNT; x++) {
        allMarkers.add(
          Marker(
            point: LatLng(
              doubleInRange(r, 37, 55),
              doubleInRange(r, -9, 30),
            ),
            builder: (context) => const Icon(
              Icons.circle,
              color: Colors.red,
              size: 12.0,
            ),
          ),
        );
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('A lot of markers')),
      drawer: buildDrawer(context, ManyMarkersPage.route),
      body: Column(
        children: [
          Slider(
            min: 0,
            max: MAX_MARKERS_COUNT.toDouble(),
            divisions: MAX_MARKERS_COUNT ~/ 500,
            label: 'Markers',
            value: _sliderVal.toDouble(),
            onChanged: (newVal) {
              _sliderVal = newVal.toInt();
              setState(() {});
            },
          ),
          Text('$_sliderVal markers'),
          Flexible(
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(50, 20),
                zoom: 5.0,
                interactiveFlags: InteractiveFlag.all - InteractiveFlag.rotate,
              ),
              layers: [
                TileLayerOptions(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayerOptions(markers: allMarkers.sublist(0, _sliderVal)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
