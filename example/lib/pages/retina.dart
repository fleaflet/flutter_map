import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class RetinaPage extends StatefulWidget {
  static const String route = '/retina';

  const RetinaPage({Key? key}) : super(key: key);

  @override
  State<RetinaPage> createState() => _RetinaPageState();
}

class _RetinaPageState extends State<RetinaPage> {
  bool? retina = false;
  double tileSize = 256;

  @override
  Widget build(BuildContext context) {
    // The default for retina is based on the screen
    retina ??= MediaQuery.of(context).devicePixelRatio > 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Retina Tiles (@2x)')),
      drawer: buildDrawer(context, RetinaPage.route),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Retina'),
                    const SizedBox(width: 10),
                    Switch.adaptive(
                      value: retina!,
                      onChanged: (v) => setState(() => retina = v),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Tile Size'),
                    const SizedBox(width: 10),
                    DropdownMenu<double>(
                      initialSelection: 256,
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(label: '256', value: 256),
                        DropdownMenuEntry(label: '512', value: 512),
                      ],
                      enableSearch: false,
                      enableFilter: false,
                      onSelected: (double? tileSize) {
                        if (tileSize == null) return;
                        setState(() {
                          this.tileSize = tileSize;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Flexible(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(51.5, -0.09),
                initialZoom: 5,
              ),
              nonRotatedChildren: const [],
              children: [
                TileLayer(
                  tileSize: tileSize,
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/{tileSize}/{z}/{x}/{y}{r}?access_token={accessToken}',
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  additionalOptions: const {
                    'tileSize': '512',
                    'accessToken':
                        'pk.eyJ1IjoiYnJhbXAiLCJhIjoiY2o4b3NnamZnMDhoMjMzcno4M3JrNm4wMSJ9.R8ove2k7wvRVVdEnlTUu4A',
                  },
                  retinaMode: retina!,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
