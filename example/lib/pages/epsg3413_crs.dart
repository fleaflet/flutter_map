import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;
import 'package:url_launcher/url_launcher.dart';

class EPSG3413Page extends StatefulWidget {
  static const String route = '/crs_epsg3413';

  const EPSG3413Page({super.key});

  @override
  EPSG3413PageState createState() => EPSG3413PageState();
}

class EPSG3413PageState extends State<EPSG3413Page> {
  late final Proj4Crs epsg3413CRS;

  final distancePoleToLat80 =
      const Distance().distance(const LatLng(90, 0), const LatLng(80, 0));

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
      const Point<double>(-4511619, -4511336),
      const Point<double>(4510883, 4510996),
    );

    maxZoom = resolutions.length - 1;

    // EPSG:3413 is a user-defined projection from a valid Proj4 definition string
    // From: http://epsg.io/3413, proj definition: http://epsg.io/3413.proj4
    // Find Projection by name or define it if not exists
    final proj4.Projection epsg3413 = proj4.Projection.get('EPSG:3413') ??
        proj4.Projection.add(
          'EPSG:3413',
          '+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 '
              '+datum=WGS84 +units=m +no_defs',
        );

    epsg3413CRS = Proj4Crs.fromFactory(
      code: 'EPSG:3413',
      proj4Projection: epsg3413,
      resolutions: resolutions,
      bounds: epsg3413Bounds,
      origins: const [Point(0, 0)],
      scales: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // These circles should have the same pixel radius on the map
    final circles = [
      const CircleMarker(
        point: LatLng(90, 0),
        radius: 20000,
        useRadiusInMeter: true,
        color: Colors.yellow,
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

    // Add latitude line at 80 degrees
    circles.add(CircleMarker(
      point: const LatLng(90, 0),
      radius: distancePoleToLat80,
      useRadiusInMeter: true,
      color: Colors.transparent,
      borderColor: Colors.black,
      borderStrokeWidth: 1,
    ));

    return Scaffold(
      appBar: AppBar(title: const Text('EPSG:3413 CRS')),
      drawer: const MenuDrawer(EPSG3413Page.route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 2),
              child: Text(
                'Tricky edge-cases with polar projections',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 16,
                ),
              ),
            ),
            const Text(
                'Details: https://github.com/fleaflet/flutter_map/pull/1295'),
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 2),
              child: SizedBox(
                width: 500,
                child: Text(
                    '• Northern and eastern directions are relative to where you are on the map:\n'
                    '  • A red dot moves north toward the yellow dot (North Pole).\n'
                    '  • A red dot moves east counter-clockwise along the black latitude line (80°).\n'
                    '• The lower left and right corners of the overlay image are the northern corners.'
                    //textAlign: TextAlign.center,
                    ),
              ),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  crs: epsg3413CRS,
                  initialCenter: const LatLng(90, 0),
                  initialZoom: 3,
                  maxZoom: maxZoom,
                ),
                children: [
                  TileLayer(
                    wmsOptions: WMSTileLayerOptions(
                      crs: epsg3413CRS,
                      transparent: true,
                      format: 'image/jpeg',
                      baseUrl:
                          'https://www.gebco.net/data_and_products/gebco_web_services/north_polar_view_wms/mapserv?',
                      layers: const ['gebco_north_polar_view'],
                    ),
                  ),
                  OverlayImageLayer(
                    overlayImages: [
                      OverlayImage(
                        bounds: LatLngBounds(
                          const LatLng(72.7911372, 162.6196478),
                          const LatLng(85.2802493, 79.794166),
                        ),
                        imageProvider: Image.asset(
                          'assets/map/epsg3413/amsr2.png',
                        ).image,
                      )
                    ],
                  ),
                  CircleLayer(circles: circles),
                  RichAttributionWidget(
                    popupInitialDisplayDuration: const Duration(seconds: 5),
                    attributions: [
                      TextSourceAttribution(
                        'Imagery reproduced from the GEBCO_2022 Grid, GEBCO '
                        'Compilation Group (2022) GEBCO 2022 Grid '
                        '(doi:10.5285/e0f0bb80-ab44-2739-e053-6c86abc0289c)',
                        onTap: () => launchUrl(
                          Uri.parse(
                            'https://www.gebco.net/data_and_products/gebco_web_services/web_map_service/#polar',
                          ),
                        ),
                      ),
                    ],
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
