import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class EPSG4326Page extends StatelessWidget {
  static const String route = 'EPSG4326 Page';

  const EPSG4326Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EPSG4326')),
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
                  minZoom: 0,
                  crs: const Epsg4326(),
                  center: const LatLng(0, 0),
                  zoom: 0,
                ),
                children: [
                  TileLayer(
                    wmsOptions: WMSTileLayerOptions(
                      crs: const Epsg4326(),
                      baseUrl: 'https://ows.mundialis.de/services/service?',
                      layers: ['TOPO-OSM-WMS'],
                    ),
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
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
