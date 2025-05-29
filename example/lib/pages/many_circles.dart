import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/number_of_items_slider.dart';
import 'package:flutter_map_example/widgets/show_no_web_perf_overlay_snackbar.dart';
import 'package:latlong2/latlong.dart';

const _maxCirclesCount = 20000;

/// On this page, [_maxCirclesCount] circles are randomly generated
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

  int numOfCircles = _maxCirclesCount ~/ 10;

  @override
  void initState() {
    super.initState();

    showNoWebPerfOverlaySnackbar(context);

    Future.microtask(() {
      final r = Random();
      for (var x = 0; x < _maxCirclesCount; x++) {
        allCircles.add(
          CircleMarker(
            point: LatLng(doubleInRange(r, 37, 55), doubleInRange(r, -9, 30)),
            color: Colors.red,
            radius: 100000,
            useRadiusInMeter: true,
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
              CircleLayer(
                circles: allCircles.take(numOfCircles).toList(),
                optimizeRadiusInMeters: true,
              ),
            ],
          ),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: NumberOfItemsSlider(
              number: numOfCircles,
              onChanged: (v) => setState(() => numOfCircles = v),
              maxNumber: _maxCirclesCount,
              itemDescription: 'Circle',
            ),
          ),
          if (!kIsWeb)
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
