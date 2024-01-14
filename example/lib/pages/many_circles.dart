import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/number_of_items_slider.dart';
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

  static const int _initialNumOfCircles = maxCirclesCount ~/ 10;
  int numOfCircles = _initialNumOfCircles;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final r = Random();
      for (var x = 0; x < maxCirclesCount; x++) {
        allCircles.add(
          CircleMarker(
            point: LatLng(doubleInRange(r, 37, 55), doubleInRange(r, -9, 30)),
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
      appBar: AppBar(title: const Text('Many Circles')),
      drawer: const MenuDrawer(ManyCirclesPage.route),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds(
                  const LatLng(55, -9),
                  const LatLng(37, 30),
                ),
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 88,
                  bottom: 192,
                ),
              ),
            ),
            children: [
              openStreetMapTileLayer,
              CircleLayer(circles: allCircles.take(numOfCircles).toList()),
            ],
          ),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: NumberOfItemsSlider(
              itemDescription: 'Circle',
              initialNumber: _initialNumOfCircles,
              onChangedNumber: (v) => setState(() => numOfCircles = v),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: PerformanceOverlay.allEnabled(),
          ),
        ],
      ),
    );
  }
}
