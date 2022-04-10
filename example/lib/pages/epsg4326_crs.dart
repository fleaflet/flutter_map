import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class EPSG4326Page extends StatelessWidget {
  static const String route = 'EPSG4326 Page';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EPSG4326')),
      drawer: buildDrawer(context, route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text('This is a map that is showing (42.58, 12.43).'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  minZoom: 0,
                  crs: const Epsg4326(),
                  center: LatLng(0, 0),
                  zoom: 0.0,
                ),
                layers: [
                  TileLayerOptions(
                    wmsOptions: WMSTileLayerOptions(
                      crs: const Epsg4326(),
                      baseUrl: 'http://ows.mundialis.de/services/service?',
                      layers: ['TOPO-OSM-WMS'],
                    ),
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
