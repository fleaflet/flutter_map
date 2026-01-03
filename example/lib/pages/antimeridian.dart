import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

/// Testing if we can fling beyond the world. We can't, due to the constraint.
class AntimeridianPage extends StatelessWidget {
  static const String route = '/antimeridian';

  const AntimeridianPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antimeridian')),
      drawer: const MenuDrawer(AntimeridianPage.route),
      body: FlutterMap(
        options: MapOptions(
          initialZoom: 2,
          cameraConstraint: CameraConstraint.contain(
            bounds: LatLngBounds(
              const LatLng(90, -180),
              const LatLng(-90, 180),
            ),
          ),
        ),
        children: [
          openStreetMapTileLayer,
        ],
      ),
    );
  }
}
