import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

/// Example dedicated to replicated worlds and related objects (e.g. Markers).
class MultiWorldsPage extends StatefulWidget {
  static const String route = '/multi_worlds';

  const MultiWorldsPage({super.key});

  @override
  State<MultiWorldsPage> createState() => _MultiWorldsPageState();
}

class _MultiWorldsPageState extends State<MultiWorldsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multi-worlds')),
      drawer: const MenuDrawer(MultiWorldsPage.route),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(51.5, -0.09),
              initialZoom: 0,
              initialRotation: 0,
            ),
            children: [
              openStreetMapTileLayer,
              MarkerLayer(
                markers: [
                  Marker(
                    point: const LatLng(48.856666, 2.351944),
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Paris'),
                          duration: Duration(seconds: 1),
                          showCloseIcon: true,
                        ),
                      ),
                      child: const Icon(Icons.location_on_rounded),
                    ),
                  ),
                  Marker(
                    point: const LatLng(34.05, -118.25),
                    child: GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Los Angeles'),
                          duration: Duration(seconds: 1),
                          showCloseIcon: true,
                        ),
                      ),
                      child: const Icon(Icons.location_city),
                    ),
                  ),
                  Marker(
                    point: const LatLng(35.689444, 139.691666),
                    child: GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tokyo'),
                          duration: Duration(seconds: 1),
                          showCloseIcon: true,
                        ),
                      ),
                      child: const Icon(Icons.backpack_outlined),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
