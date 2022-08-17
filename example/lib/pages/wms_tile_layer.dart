import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class WMSLayerPage extends StatelessWidget {
  static const String route = 'WMS layer';

  const WMSLayerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WMS Layer')),
      drawer: buildDrawer(context, route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text('This is a map that is showing (42.58, 12.43).'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(42.58, 12.43),
                  zoom: 6,
                ),
                children: [
                  TileLayer(
                    wmsOptions: WMSTileLayerOptions(
                      baseUrl: 'https://{s}.s2maps-tiles.eu/wms/?',
                      layers: ['s2cloudless-2018_3857'],
                    ),
                    subdomains: const ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
