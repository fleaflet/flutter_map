import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class CirclePage extends StatelessWidget {
  static const String route = 'circle';

  const CirclePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final circleMarkers = <CircleMarker>[
      CircleMarker(
          point: const LatLng(51.5, -0.09),
          color: Colors.blue.withOpacity(0.7),
          borderStrokeWidth: 2,
          useRadiusInMeter: true,
          radius: 2000 // 2000 meters | 2 km
          ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Circle')),
      drawer: buildDrawer(context, route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text('This is a map that is showing (51.5, -0.9).'),
            ),
            Flexible(
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(51.5, -0.09),
                  initialZoom: 11,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  ),
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
