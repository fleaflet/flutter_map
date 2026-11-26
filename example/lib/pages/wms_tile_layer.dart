import 'package:flutter/gestures.dart';
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
              baseUrl: 'https://tiles.maps.eox.at/wms?',
              layers: const ['s2cloudless-2025_3857'],
            ),
            subdomains: const ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
            userAgentPackageName: 'dev.fleaflet.flutter_map.example',
          ),
          SafeArea(
            child: ExpandableAttributionLayer(
              expandedBuilder: (context) => Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'EOxCloudless - https://cloudless.eox.at',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: DefaultTextStyle.of(
                          context,
                        ).style.color,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () =>
                            launchUrl(Uri.parse('https://cloudless.eox.at/')),
                    ),
                    const TextSpan(text: ' by '),
                    TextSpan(
                      text: 'EOX IT Services GmbH',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: DefaultTextStyle.of(
                          context,
                        ).style.color,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(Uri.parse('https://eox.at/')),
                    ),
                    const TextSpan(
                      text:
                          ' (Contains modified Copernicus Sentinel data 2025), '
                          'Overlay { Data © ',
                    ),
                    TextSpan(
                      text: 'OpenStreetMap',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: DefaultTextStyle.of(
                          context,
                        ).style.color,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                        ),
                    ),
                    const TextSpan(text: ' contributors, Rendering © '),
                    TextSpan(
                      text: 'EOX',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: DefaultTextStyle.of(
                          context,
                        ).style.color,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(Uri.parse('https://eox.at/')),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'MapServer',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: DefaultTextStyle.of(
                          context,
                        ).style.color,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(
                          Uri.parse('https://github.com/mapserver/basemaps'),
                        ),
                    ),
                    const TextSpan(text: ' }'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
