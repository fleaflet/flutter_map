import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class WMSLayerPage extends StatelessWidget {
  static const String route = '/wms_layer';

  const WMSLayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WMS Layer')),
      drawer: const MenuDrawer(route),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(42.58, 12.43),
          initialZoom: 6,
        ),
        children: [
          TileLayer(
            wmsOptions: WMSTileLayerOptions(
              baseUrl: 'https://{s}.s2maps-tiles.eu/wms/?',
              layers: const ['s2cloudless-2021_3857'],
            ),
            subdomains: const ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
            userAgentPackageName: 'dev.fleaflet.flutter_map.example',
          ),
          RichAttributionWidget(
            popupInitialDisplayDuration: const Duration(seconds: 5),
            attributions: [
              TextSourceAttribution(
                'Sentinel-2 cloudless - https://s2maps.eu by EOX IT Services GmbH',
                onTap: () => launchUrl(Uri.parse('https://s2maps.eu')),
              ),
              const TextSourceAttribution(
                'Modified Copernicus Sentinel data 2021',
              ),
              TextSourceAttribution(
                'Rendering: EOX::Maps',
                onTap: () => launchUrl(Uri.parse('https://maps.eox.at/')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
