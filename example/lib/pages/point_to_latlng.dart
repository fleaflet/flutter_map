import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class PointToLatLngPage extends StatefulWidget {
  static const String route = 'point_to_latlng';

  @override
  PointToLatlngPage createState() {
    return PointToLatlngPage();
  }
}

class PointToLatlngPage extends State<PointToLatLngPage> {
  late final MapController mapController;
  final pointX = 100.0;
  final pointY = 100.0;
  final pointSize = 20.0;
  late final mapEventSubscription;

  LatLng? latLng;

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    mapEventSubscription = mapController.mapEventStream.listen(onMapEvent);

    mapController.onReady.then((_) => _updatePointLatLng());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PointToLatlng')),
      drawer: buildDrawer(context, PointToLatLngPage.route),
      body: Stack(
        children: [
          Container(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                center: LatLng(51.5, -0.09),
                zoom: 5.0,
                maxZoom: 5.0,
                minZoom: 3.0,
              ),
              layers: [
                TileLayerOptions(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c']),
              ],
            ),
          ),
          Container(
              color: Colors.white,
              height: 60,
              child: Center(
                  child: Text(
                'top left of square is hovering ${latLng?.latitude},${latLng?.longitude}',
                textAlign: TextAlign.center,
              ))),
          Positioned(
              top: pointY,
              left: pointX,
              child: Container(
                  color: Colors.red, width: pointSize, height: pointSize))
        ],
      ),
    );
  }

  void onMapEvent(MapEvent mapEvent) {
    if (mapEvent is MapEventMove) {
      _updatePointLatLng();
    }
  }

  void _updatePointLatLng() {
    final latLng = mapController.pointToLatLng(CustomPoint(pointX, pointY));

    setState(() {
      this.latLng = latLng;
    });
  }
}
