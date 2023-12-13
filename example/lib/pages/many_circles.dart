import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

const maxCirclesCount = 20000;

/// On this page, [maxCirclesCount] circles are randomly generated
/// across europe, and then you can limit them with a slider
///
/// This way, you can test how map performs under a lot of circles
class ManyCirclesPage extends StatefulWidget {
  static const String route = '/many_circles';

  const ManyCirclesPage({super.key});

  @override
  ManyCirclesPageState createState() => ManyCirclesPageState();
}

class ManyCirclesPageState extends State<ManyCirclesPage> {
  double doubleInRange(Random source, num start, num end) =>
      source.nextDouble() * (end - start) + start;
  List<CircleMarker> allCircles = [];

  int _sliderVal = maxCirclesCount ~/ 10;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final r = Random();
      for (var x = 0; x < maxCirclesCount; x++) {
        allCircles.add(
          CircleMarker(
            point: LatLng(
              doubleInRange(r, 37, 55),
              doubleInRange(r, -9, 30),
            ),
            color: Colors.red,
            radius: 5,
          ),
        );
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('A lot of circles')),
      drawer: const MenuDrawer(ManyCirclesPage.route),
      body: Column(
        children: [
          Slider(
            min: 0,
            max: maxCirclesCount.toDouble(),
            divisions: maxCirclesCount ~/ 500,
            label: 'Circles',
            value: _sliderVal.toDouble(),
            onChanged: (newVal) {
              _sliderVal = newVal.toInt();
              setState(() {});
            },
          ),
          Text('$_sliderVal circles'),
          Flexible(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(50, 20),
                initialZoom: 5,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlags.all(rotate: false),
                ),
              ),
              children: [
                openStreetMapTileLayer,
                CircleLayer(
                    circles: allCircles.sublist(
                        0, min(allCircles.length, _sliderVal))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
