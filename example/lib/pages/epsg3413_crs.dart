import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;

import '../../widgets/drawer.dart';

class EPSG3413Page extends StatefulWidget {
  static const String route = 'EPSG3413 Page';

  const EPSG3413Page({Key? key}) : super(key: key);

  @override
  _EPSG3413PageState createState() => _EPSG3413PageState();
}

class _EPSG3413PageState extends State<EPSG3413Page> {
  late final Proj4Crs epsg3413CRS;

  double? maxZoom;

  @override
  void initState() {
    super.initState();

    // 9 example zoom level resolutions
    final resolutions = <double>[
      32768,
      16384,
      8192,
      4096,
      2048,
      1024,
      512,
      256,
      128,
    ];

    final epsg3413Bounds = Bounds<double>(
      const CustomPoint<double>(-4511619.0, -4511336.0),
      const CustomPoint<double>(4510883.0, 4510996.0),
    );

    maxZoom = (resolutions.length - 1).toDouble();

    // EPSG:3413 is a user-defined projection from a valid Proj4 definition string
    // From: http://epsg.io/3413, proj definition: http://epsg.io/3413.proj4
    // Find Projection by name or define it if not exists
    final proj4.Projection epsg3413 = proj4.Projection.get('EPSG:3413') ??
        proj4.Projection.add('EPSG:3413',
            '+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs');

    epsg3413CRS = Proj4Crs.fromFactory(
      code: 'EPSG:3413',
      proj4Projection: epsg3413,
      resolutions: resolutions,
      bounds: epsg3413Bounds,
      origins: [const CustomPoint(0, 0)],
      scales: null,
      transformation: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // These circles should have the same pixel radius on the map
    final circles = [
      CircleMarker(
        point: LatLng(90, 0),
        radius: 20000,
        useRadiusInMeter: true,
        color: Colors.red,
      )
    ];
    for (final lon in [-90.0, 0.0, 90.0, 180.0]) {
      circles.add(CircleMarker(
        point: LatLng(80, lon),
        radius: 20000,
        useRadiusInMeter: true,
        color: Colors.red,
      ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('EPSG:3413 CRS')),
      drawer: buildDrawer(context, EPSG3413Page.route),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 2.0),
              child: Text(
                'This map is in EPSG:3413',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 16.0,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 2.0),
              child: Text(
                'This page demonstrates some tricky edge-cases for maps with a polar projection.',
              ),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  crs: epsg3413CRS,
                  center: LatLng(90, 0),
                  zoom: 3.0,
                  maxZoom: maxZoom,
                ),
                layers: [
                  TileLayerOptions(
                    opacity: 1,
                    backgroundColor: Colors.transparent,
                    wmsOptions: WMSTileLayerOptions(
                      crs: epsg3413CRS,
                      transparent: true,
                      format: 'image/jpeg',
                      baseUrl:
                          'https://www.gebco.net/data_and_products/gebco_web_services/north_polar_view_wms/mapserv?',
                      layers: ['gebco_north_polar_view'],
                    ),
                  ),
                  CircleLayerOptions(
                    circles: circles,
                  ),
                  OverlayImageLayerOptions(
                    overlayImages: [
                      OverlayImage(
                        bounds: LatLngBounds(
                          LatLng(72.7911372, 162.6196478),
                          LatLng(85.2802493, 79.794166),
                        ),
                        imageProvider: Image.asset(
                          'map/epsg3413/amsr2.png',
                        ).image,
                      )
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
}
