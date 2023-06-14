import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class SlidingMapPage extends StatelessWidget {
  static const String route = '/sliding_map';
  static const northEast = LatLng(56.7378, 11.6644);
  static const southWest = LatLng(56.6877, 11.5089);

  const SlidingMapPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sliding Map')),
      drawer: buildDrawer(context, route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                  'This is a map that can be panned smoothly when the boundaries are reached.'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(56.704173, 11.543808),
                  minZoom: 12,
                  maxZoom: 14,
                  initialZoom: 13,
                  frameConstraint: FrameConstraint.contain(
                    bounds: LatLngBounds(northEast, southWest),
                  ),
                ),
                children: [
                  TileLayer(
                    tileProvider: AssetTileProvider(),
                    maxZoom: 14,
                    urlTemplate: 'assets/map/anholt_osmbright/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(
                    anchorPos: AnchorPos.align(AnchorAlign.top),
                    markers: [
                      Marker(
                        point: northEast,
                        builder: (context) => _cornerMarker(Icons.north_east),
                        anchorPos: AnchorPos.align(AnchorAlign.bottomLeft),
                      ),
                      Marker(
                        point: LatLng(southWest.latitude, northEast.longitude),
                        builder: (context) => _cornerMarker(Icons.south_east),
                        anchorPos: AnchorPos.align(AnchorAlign.topLeft),
                      ),
                      Marker(
                        point: southWest,
                        builder: (context) => _cornerMarker(Icons.south_west),
                        anchorPos: AnchorPos.align(AnchorAlign.topRight),
                      ),
                      Marker(
                        point: LatLng(northEast.latitude, southWest.longitude),
                        builder: (context) => _cornerMarker(Icons.north_west),
                        anchorPos: AnchorPos.align(AnchorAlign.bottomRight),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cornerMarker(IconData iconData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        border: Border.all(color: Colors.black),
      ),
      width: 30,
      height: 30,
      child: Icon(iconData),
    );
  }
}
