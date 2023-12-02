import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';

const maxMarkersCount = 20000;

/// On this page, [maxMarkersCount] markers are randomly generated
/// across europe, and then you can limit them with a slider
///
/// This way, you can test how map performs under a lot of markers
class ManyMarkersPage extends StatefulWidget {
  static const String route = '/many_markers';

  const ManyMarkersPage({super.key});

  @override
  ManyMarkersPageState createState() => ManyMarkersPageState();
}

class ManyMarkersPageState extends State<ManyMarkersPage> {
  double doubleInRange(Random source, num start, num end) =>
      source.nextDouble() * (end - start) + start;
  List<Marker> allMarkers = [];

  int _sliderVal = maxMarkersCount ~/ 10;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final r = Random();
      for (var x = 0; x < maxMarkersCount; x++) {
        allMarkers.add(
          Marker(
            point: (lat: doubleInRange(r, 37, 55), lon: doubleInRange(r, -9, 30)),
            height: 12,
            width: 12,
            child: ColoredBox(color: Colors.blue[900]!),
          ),
        );
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('A lot of markers')),
      drawer: const MenuDrawer(ManyMarkersPage.route),
      body: Column(
        children: [
          Slider(
            min: 0,
            max: maxMarkersCount.toDouble(),
            divisions: maxMarkersCount ~/ 500,
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
              options: const MapOptions(
                initialCenter: (lat: 50, lon: 20),
                initialZoom: 5,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all - InteractiveFlag.rotate,
                ),
              ),
              children: [
                openStreetMapTileLayer,
                MarkerLayer(
                  markers: allMarkers.sublist(
                    0,
                    min(allMarkers.length, _sliderVal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
