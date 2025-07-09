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
/// across London, and then you can limit them with a slider
///
/// This way, you can test how map performs under a lot of markers
class ManyMarkersPage extends StatefulWidget {
  static const String route = '/many_markers';

  const ManyMarkersPage({super.key});

  @override
  ManyMarkersPageState createState() => ManyMarkersPageState();
}

class ManyMarkersPageState extends State<ManyMarkersPage> {
  List<Marker> allMarkers = [];

  int numOfMarkers = _maxMarkersCount ~/ 10;
  final LatLng london = const LatLng(51.5074, -0.1278);

  @override
  void initState() {
    super.initState();

    showNoWebPerfOverlaySnackbar(context);

    Future.microtask(() {
      final r = Random(10);

      for (var x = 0; x < _maxMarkersCount; x++) {
        final double angle = r.nextDouble() * 2 * pi;
        final double distance = r.nextDouble() * 0.5;
        final double latOffset = distance * sin(angle) * (0.7 + r.nextDouble() * 0.6);
        final double lonOffset = distance * cos(angle) * (0.7 + r.nextDouble() * 0.6);
        final double lat = london.latitude + latOffset;
        final double lon = london.longitude + lonOffset;
        final LatLng position = LatLng(lat, lon);

        allMarkers.add(Marker(
            point: position,
            width: 30,
            height: 30,
            child: GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tapped existing marker: Location Lat: ${position.latitude}, Lon: ${position.longitude}'),
                  duration: const Duration(seconds: 1),
                  showCloseIcon: true,
                ),
              ),
              child: Icon(Icons.location_pin, size: 30, color: getRandomColor(r)),
            )));
      }
      setState(() {});
    });
  }

  Color getRandomColor(Random source) {
    return Color.fromARGB(
      255,
      source.nextInt(256),
      source.nextInt(256),
      source.nextInt(256),
    );
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
                  const LatLng(50, -0.5),
                  const LatLng(53, 0.3),
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
