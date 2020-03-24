import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

class AutoCachedTilesPage extends StatelessWidget {
  static const String route = '/auto_cached_tiles';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AutoCachedTiles Map')),
      drawer: buildDrawer(context, route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                  'This is an offline map that is showing Anholt Island, Denmark.'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng( 55.753215, 37.622504),
                  minZoom: 12.0,
                  maxZoom: 18.0,
                  zoom: 13.0,
                ),
                layers: [
                  TileLayerOptions(
                    tileProvider: StorageCachingTileProvider(),
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
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
