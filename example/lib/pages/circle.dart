import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';

class CirclePage extends StatelessWidget {
  static const String route = '/circle';

  const CirclePage({super.key});

  @override
  Widget build(BuildContext context) {
    final circleMarkers = <CircleMarker>[
      CircleMarker(
        point: const LatLng(51.5, -0.09),
        color: Colors.blue.withOpacity(0.7),
        borderColor: Colors.black,
        borderStrokeWidth: 2,
        useRadiusInMeter: true,
        radius: 2000, // 2000 meters
      ),
      CircleMarker(
        point: const LatLng(51.4937, -0.6638),
        // Dorney Lake is ~2km long
        color: Colors.green.withOpacity(0.9),
        borderColor: Colors.black,
        borderStrokeWidth: 2,
        useRadiusInMeter: true,
        radius: 1000, // 1000 meters
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Circle')),
      drawer: const MenuDrawer(route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('This is a map that is showing (51.5, -0.09).'),
            ),
            Flexible(
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(51.5, -0.09),
                  initialZoom: 11,
                ),
                children: [
                  openStreetMapTileLayer,
                  CircleLayer(circles: circleMarkers),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
