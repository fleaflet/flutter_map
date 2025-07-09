import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/notice_banner.dart';
import 'package:latlong2/latlong.dart';

class AbortObsoleteRequestsPage extends StatefulWidget {
  static const String route = '/abort_obsolete_requests_page';

  const AbortObsoleteRequestsPage({super.key});

  @override
  State<AbortObsoleteRequestsPage> createState() =>
      _AbortUnnecessaryRequestsPage();
}

class _AbortUnnecessaryRequestsPage extends State<AbortObsoleteRequestsPage> {
  bool _abortingEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abort Obsolete Requests')),
      drawer: const MenuDrawer(AbortObsoleteRequestsPage.route),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Switch.adaptive(
                value: _abortingEnabled,
                onChanged: (value) => setState(() => _abortingEnabled = value),
              ),
            ),
          ),
          const NoticeBanner.recommendation(
            text: 'Since v8.2.0, in-flight HTTP requests for tiles which are '
                'no longer displayed are aborted by default.',
            url: 'https://docs.fleaflet.dev/layers/tile-layer/tile-providers',
            sizeTransition: 870,
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
                  key: ValueKey(_abortingEnabled),
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  tileProvider: NetworkTileProvider(
                    abortObsoleteRequests: _abortingEnabled,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
