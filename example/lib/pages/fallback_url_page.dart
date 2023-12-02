import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/notice_banner.dart';
import 'package:latlong2/latlong.dart';

class FallbackUrlPage extends StatelessWidget {
  static const String route = '/fallback_url';

  const FallbackUrlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fallback URL')),
      drawer: const MenuDrawer(route),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Map with a fake (innaccessible) URL should use the fallback URL',
              textAlign: TextAlign.center,
            ),
          ),
          const NoticeBanner.warning(
            text: 'Relying on a fallback URL may have a negative performance '
                'impact',
            url: 'https://docs.fleaflet.dev/layers/tile-layer/tile-providers',
            sizeTransition: 650,
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
                  fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  tileProvider: CancellableNetworkTileProvider(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
