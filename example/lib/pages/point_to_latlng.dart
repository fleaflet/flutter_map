import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class PointToLatLngPage extends StatefulWidget {
  static const String route = 'point_to_latlng';

  const PointToLatLngPage({Key? key}) : super(key: key);

  @override
  PointToLatlngPage createState() {
    return PointToLatlngPage();
  }
}

class PointToLatlngPage extends State<PointToLatLngPage> {
  late final MapController mapController;
  late final StreamSubscription mapEventSubscription;
  final pointSize = 40.0;
  final pointY = 200.0;

  LatLng? latLng;

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    mapEventSubscription = mapController.mapEventStream
        .listen((mapEvent) => onMapEvent(mapEvent, context));

    Future.delayed(Duration.zero, () {
      mapController.onReady.then((_) => _updatePointLatLng(context));
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
            child: const Icon(Icons.rotate_right),
            onPressed: () => mapController.rotate(60.0),
          ),
          const SizedBox(height: 15),
          FloatingActionButton(
            child: const Icon(Icons.cancel),
            onPressed: () => mapController.rotate(0.0),
          ),
        ],
      ),
      drawer: buildDrawer(context, PointToLatLngPage.route),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: LatLng(51.5, -0.09),
              zoom: 5.0,
              minZoom: 3.0,
            ),
            children: [
              TileLayerWidget(
                  options: TileLayerOptions(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'])),
              if (latLng != null)
                MarkerLayerWidget(
                    options: MarkerLayerOptions(
                  markers: [
                    Marker(
                      width: pointSize,
                      height: pointSize,
                      point: latLng!,
                      builder: (ctx) => const FlutterLogo(),
                    )
                  ],
                ))
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

  void onMapEvent(MapEvent mapEvent, BuildContext context) {
    _updatePointLatLng(context);
  }

  void _updatePointLatLng(context) {
    final pointX = _getPointX(context);

    final latLng = mapController.pointToLatLng(CustomPoint(pointX, pointY));

    setState(() {
      this.latLng = latLng;
    });
  }

  double _getPointX(BuildContext context) {
    return MediaQuery.of(context).size.width / 2;
  }

  @override
  void dispose() {
    super.dispose();
    mapEventSubscription.cancel();
  }
}
