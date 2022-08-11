import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class PointToLatLngPage extends StatefulWidget {
  static const String route = 'point_to_latlng';

  const PointToLatLngPage({Key? key}) : super(key: key);

  @override
  PointToLatlngPage createState() {
    return PointToLatlngPage();
  }
}

class PointToLatlngPage extends State<PointToLatLngPage> {
  late final MapController mapController = MapController();
  final pointSize = 40.0;
  final pointY = 200.0;

  LatLng? latLng;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      updatePoint(null, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PointToLatlng')),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'rotate',
            child: const Icon(Icons.rotate_right),
            onPressed: () => mapController.rotate(60),
          ),
          const SizedBox(height: 15),
          FloatingActionButton(
            heroTag: 'cancel',
            child: const Icon(Icons.cancel),
            onPressed: () => mapController.rotate(0),
          ),
        ],
      ),
      drawer: buildDrawer(context, PointToLatLngPage.route),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              onMapEvent: (event) {
                updatePoint(null, context);
              },
              center: LatLng(51.5, -0.09),
              zoom: 5,
              minZoom: 3,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'dev.fleaflet.flutter_map.example',
              ),
              if (latLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: pointSize,
                      height: pointSize,
                      point: latLng!,
                      builder: (ctx) => const FlutterLogo(),
                    )
                  ],
                )
            ],
          ),
          Container(
              color: Colors.white,
              height: 60,
              child: Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'flutter logo (${latLng?.latitude.toStringAsPrecision(4)},${latLng?.longitude.toStringAsPrecision(4)})',
                    textAlign: TextAlign.center,
                  ),
                ],
              ))),
          Positioned(
              top: pointY - pointSize / 2,
              left: _getPointX(context) - pointSize / 2,
              child: Icon(Icons.crop_free, size: pointSize))
        ],
      ),
    );
  }

  void updatePoint(MapEvent? event, BuildContext context) {
    final pointX = _getPointX(context);
    setState(() {
      latLng = mapController.pointToLatLng(CustomPoint(pointX, pointY));
    });
  }

  double _getPointX(BuildContext context) {
    return MediaQuery.of(context).size.width / 2;
  }
}
