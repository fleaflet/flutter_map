import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class SecondaryTapPage extends StatelessWidget {
  const SecondaryTapPage({super.key});

  static const route = '/secondary_tap';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secondary Tap')),
      drawer: const MenuDrawer(route),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('This is a map that supports secondary tap events.'),
          ),
          Flexible(
            child: FlutterMap(
              options: MapOptions(
                onSecondaryTap: (tapPos, latLng) {
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(content: Text('Secondary tap at $latLng')),
                  );
                },
                initialCenter: const LatLng(51.5, -0.09),
                initialZoom: 5,
              ),
              children: [openStreetMapTileLayer],
            ),
          ),
        ],
      ),
    );
  }
}
