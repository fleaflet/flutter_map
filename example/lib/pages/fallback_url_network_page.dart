import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';

class FallbackUrlNetworkPage extends StatelessWidget {
  static const String route = '/fallback_url_network';

  const FallbackUrlNetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fallback URL NetworkTileProvider')),
      drawer: const MenuDrawer(route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Map with a fake url should use the fallback, '
                'showing (51.5, -0.9).',
              ),
            ),
            Flexible(
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(51.5, -0.09),
                  initialZoom: 5,
                ),
                children: [
                  TileLayer(
                    // use an invalid domain as example as an provider that
                    // is not reachable
                    urlTemplate:
                        'https://not-a-real-provider-url.local/{z}/{x}/{y}.png',
                    fallbackUrl:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                    tileProvider: CancellableNetworkTileProvider(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
