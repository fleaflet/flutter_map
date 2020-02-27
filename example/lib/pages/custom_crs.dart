import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;

import '../widgets/drawer.dart';

class CustomCrsPage extends StatefulWidget {
  static const String route = 'custom_crs';

  /// EPSG:4326 is a predefined projection ships with proj4dart
  static final proj4.Projection epsg4326 = proj4.Projection('EPSG:4326');

  /// EPSG:3413 is a user-defined projection from a valid Proj4 definition string
  /// From: http://epsg.io/3413, proj definition: http://epsg.io/3413.proj4
  static final proj4.Projection epsg3413 = proj4.Projection.add('EPSG:3413',
      '+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs');
  static final List<double> resolutions = [
    4096,
    2048,
    1024,
    512,
    256,
    128,
  ];

  @override
  _CustomCrsPageState createState() => _CustomCrsPageState();
}

class _CustomCrsPageState extends State<CustomCrsPage> {
  var point = proj4.Point(x: 65.05166470332148, y: -19.171744826394896);
  var initText = 'Map centered to';
  final double maxZoom = (CustomCrsPage.resolutions.length - 1).toDouble();

  final Proj4Crs epsg3413CRS = Proj4Crs.fromFactory(
      code: 'EPSG:3413',
      proj4Projection: CustomCrsPage.epsg3413,
      resolutions: CustomCrsPage.resolutions);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Custom CRS (EPSG:3413)')),
      drawer: buildDrawer(context, CustomCrsPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                  '$initText (${point.x.toStringAsFixed(5)}, ${point.y.toStringAsFixed(5)}) in EPSG:4326.'),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                  'Which is (${CustomCrsPage.epsg4326.transform(CustomCrsPage.epsg3413, point).x.toStringAsFixed(2)}, ${CustomCrsPage.epsg4326.transform(CustomCrsPage.epsg3413, point).y.toStringAsFixed(2)}) in EPSG:3413.'),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text('Tap on map to get more coordinates!'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  // Set the default CRS
                  crs: epsg3413CRS,
                  center: LatLng(point.x, point.y),
                  zoom: 1.0,
                  maxZoom: maxZoom,
                  onTap: (p) => setState(() {
                    initText = 'You clicked at';
                    point = proj4.Point(x: p.latitude, y: p.longitude);
                  }),
                ),
                layers: [
                  TileLayerOptions(
                    opacity: 1.0,
                    backgroundColor: Colors.white.withOpacity(0),
                    wmsOptions: WMSTileLayerOptions(
                      // Set the WMS layer's CRS
                      crs: epsg3413CRS,
                      transparent: true,
                      format: 'image/jpeg',
                      baseUrl:
                          'https://www.gebco.net/data_and_products/gebco_web_services/north_polar_view_wms/mapserv?',
                      layers: ['gebco_north_polar_view'],
                    ),
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