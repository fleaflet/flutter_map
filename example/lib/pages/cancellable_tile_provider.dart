import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/notice_banner.dart';
import 'package:latlong2/latlong.dart';

class CancellableTileProviderPage extends StatefulWidget {
  static const String route = '/cancellable_tile_provider_page';

  const CancellableTileProviderPage({super.key});

  @override
  State<CancellableTileProviderPage> createState() =>
      _CancellableTileProviderPageState();
}

class _CancellableTileProviderPageState
    extends State<CancellableTileProviderPage> {
  bool _providerEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cancellable Tile Provider')),
      drawer: const MenuDrawer(CancellableTileProviderPage.route),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SwitchListTile.adaptive(
                title: const Text('Use CancellableNetworkTileProvider'),
                value: _providerEnabled,
                onChanged: (value) => setState(() => _providerEnabled = value),
              ),
            ),
          ),
          const NoticeBanner.recommendation(
            text:
                'This tile provider cancels unnecessary HTTP requests, which can help performance (especially on the web)',
            url:
                'https://docs.fleaflet.dev/layers/tile-layer/tile-providers#cancellablenetworktileprovider',
            sizeTransition: 905,
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(51.5, -0.09),
                initialZoom: 5,
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(
                    const LatLng(-90, -180),
                    const LatLng(90, 180),
                  ),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  tileProvider: _providerEnabled
                      ? CancellableNetworkTileProvider()
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
