import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/number_of_items_slider.dart';
import 'package:flutter_map_example/widgets/show_no_web_perf_overlay_snackbar.dart';
import 'package:latlong2/latlong.dart';

const _maxMarkersCount = 20000;

/// On this page, [_maxMarkersCount] markers are randomly generated
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

  int numOfMarkers = _maxMarkersCount ~/ 10;

  @override
  void initState() {
    super.initState();

    showNoWebPerfOverlaySnackbar(context);

    Future.microtask(() {
      final r = Random();
      for (var x = 0; x < _maxMarkersCount; x++) {
        allMarkers.add(
          Marker(
            point: LatLng(doubleInRange(r, 37, 55), doubleInRange(r, -9, 30)),
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
      appBar: AppBar(title: const Text('Many Markers')),
      drawer: const MenuDrawer(ManyMarkersPage.route),
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
              MarkerLayer(markers: allMarkers.take(numOfMarkers).toList()),
            ],
          ),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: NumberOfItemsSlider(
              number: numOfMarkers,
              onChanged: (v) => setState(() => numOfMarkers = v),
              maxNumber: _maxMarkersCount,
              itemDescription: 'Marker',
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
