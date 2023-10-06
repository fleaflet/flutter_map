import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class MovingMarkersPage extends StatefulWidget {
  static const String route = '/moving_markers';

  const MovingMarkersPage({Key? key}) : super(key: key);

  @override
  _MovingMarkersPageState createState() {
    return _MovingMarkersPageState();
  }
}

class _MovingMarkersPageState extends State<MovingMarkersPage> {
  Marker? _marker;
  late final Timer _timer;
  int _markerIndex = 0;

  static const _markers = [
    Marker(
      width: 80,
      height: 80,
      point: LatLng(51.5, -0.09),
      child: FlutterLogo(),
    ),
    Marker(
      width: 80,
      height: 80,
      point: LatLng(53.3498, -6.2603),
      child: FlutterLogo(),
    ),
    Marker(
      width: 80,
      height: 80,
      point: LatLng(48.8566, 2.3522),
      child: FlutterLogo(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _marker = _markers[_markerIndex];
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _marker = _markers[_markerIndex];
        _markerIndex = (_markerIndex + 1) % _markers.length;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      drawer: buildDrawer(context, MovingMarkersPage.route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text('This is a map that is showing (51.5, -0.9).'),
            ),
            Flexible(
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(51.5, -0.09),
                  initialZoom: 5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  ),
                  MarkerLayer(markers: [_marker!]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
