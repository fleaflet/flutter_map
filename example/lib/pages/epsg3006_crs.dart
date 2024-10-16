import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;

typedef HitValue = ({String title, String subtitle});

class EPSG3006Page extends StatefulWidget {
  static const String route = '/crs_epsg3006';

  const EPSG3006Page({super.key});

  @override
  State<EPSG3006Page> createState() => _EPSG3006PageState();
}

class _EPSG3006PageState extends State<EPSG3006Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EPSG:3006 CRS')),
      drawer: const MenuDrawer(EPSG3006Page.route),
      body: Stack(
        children: [
          // OSM based, uses somewhat strange bounds.
          // No access restrictions or fees in GetCapabilities as of 2024-10-15
          FlutterMap(
            options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: LatLngBounds(
                    const LatLng(61.285991891313344, 17.006922572652666),
                    const LatLng(61.279648385340494, 17.018309853620366),
                  ),
                ),
                crs: Proj4Crs.fromFactory(
                  code: 'EPSG:3006',
                  proj4Projection: proj4.Projection.add(
                    'EPSG:3006',
                    '+proj=utm +zone=33 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs +type=crs',
                  ),
                  origins: const [
                    Point(-58122915.354077406, 19995929.885879364),
                  ],
                  resolutions: const <double>[
                    4096,
                    2048,
                    1024,
                    512,
                    256,
                    128,
                    64,
                    32,
                    16,
                    8,
                    4,
                    2,
                    1,
                    0.5,
                    0.25,
                    0.125
                  ],
                )),
            children: [
              TileLayer(
                  tileBuilder: coordinateDebugTileBuilder,
                  urlTemplate:
                      'https://maps.trafikinfo.trafikverket.se/MapService/wmts.axd/BakgrundskartaNorden.gpkg?layer=Background&style=default&tilematrixset=Default.256.3006&Service=WMTS&Request=GetTile&Version=1.0.0&Format=image%2Fpng&TileMatrix={z}&TileCol={x}&TileRow={y}')
            ],
          ),
        ],
      ),
    );
  }
}
