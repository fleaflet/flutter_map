import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class RetinaPage extends StatefulWidget {
  static const String route = '/retina';

  const RetinaPage({Key? key}) : super(key: key);

  @override
  State<RetinaPage> createState() => _RetinaPageState();
}

class _RetinaPageState extends State<RetinaPage> {
  bool fmRetina = false;
  bool urlRetina = false;
  double fmTileSize = 256;
  double urlTileSize = 256;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retina Tiles')),
      drawer: buildDrawer(context, RetinaPage.route),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Text(
                        'flutter_map Settings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox.square(dimension: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Simulate Retina'),
                          const SizedBox.square(dimension: 10),
                          Switch.adaptive(
                            value: fmRetina,
                            onChanged: (v) => setState(() => fmRetina = v),
                          ),
                        ],
                      ),
                      const SizedBox.square(dimension: 10),
                      DropdownMenu<double>(
                        label: const Text('Tile Size'),
                        leadingIcon: const Icon(Icons.photo_size_select_large),
                        initialSelection: 256,
                        enableSearch: false,
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(label: '256px', value: 256),
                          DropdownMenuEntry(label: '512px', value: 512),
                        ],
                        onSelected: (tileSize) {
                          if (tileSize == null) return;
                          setState(() => fmTileSize = tileSize);
                        },
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 42),
                  Column(
                    children: [
                      const Text(
                        'URL Options',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox.square(dimension: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('"@2x" Retina'),
                          const SizedBox.square(dimension: 10),
                          Switch.adaptive(
                            value: urlRetina,
                            onChanged: (v) => setState(() => urlRetina = v),
                          ),
                        ],
                      ),
                      const SizedBox.square(dimension: 10),
                      DropdownMenu<double>(
                        label: const Text('Tile Size'),
                        leadingIcon: const Icon(Icons.photo_size_select_large),
                        initialSelection: 256,
                        enableSearch: false,
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(label: '256px', value: 256),
                          DropdownMenuEntry(label: '512px', value: 512),
                        ],
                        onSelected: (tileSize) {
                          if (tileSize == null) return;
                          setState(() => urlTileSize = tileSize);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(51.5, -0.09),
                initialZoom: 5,
              ),
              nonRotatedChildren: [
                RichAttributionWidget(
                  attributions: [
                    LogoSourceAttribution(
                      Image.asset(
                        "assets/mapbox-logo-white.png",
                        color: Colors.black,
                      ),
                      height: 16,
                    ),
                    TextSourceAttribution(
                      'Mapbox',
                      onTap: () => launchUrl(
                          Uri.parse('https://www.mapbox.com/about/maps/')),
                    ),
                    TextSourceAttribution(
                      'OpenStreetMap',
                      onTap: () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright')),
                    ),
                    TextSourceAttribution(
                      'Improve this map',
                      prependCopyright: false,
                      onTap: () => launchUrl(
                          // TODO This URL can end in #/-74.5/40/10 to specify
                          // the location. Make this change automagically.
                          Uri.parse('https://www.mapbox.com/map-feedback/')),
                    ),
                  ],
                ),
              ],
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/{urlTileSize}/{z}/{x}/{y}{urlRetinaMode}?access_token={accessToken}',
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  additionalOptions: {
                    'urlTileSize': urlTileSize.toStringAsFixed(0),
                    'urlRetinaMode': urlRetina ? '{r}' : '',
                    'accessToken':
                        'pk.eyJ1IjoiYnJhbXAiLCJhIjoiY2o4b3NnamZnMDhoMjMzcno4M3JrNm4wMSJ9.R8ove2k7wvRVVdEnlTUu4A',
                  },
                  retinaMode: fmRetina,
                  tileSize: fmTileSize,
                  tileBuilder: (context, tileWidget, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(width: 2, color: Colors.white),
                    ),
                    position: DecorationPosition.foreground,
                    child: tileWidget,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
