import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class MovingMarkersPage extends StatefulWidget {
  static const String route = '/moving_markers';

  const MovingMarkersPage({super.key});

  @override
  MovingMarkersPageState createState() => MovingMarkersPageState();
}

class MovingMarkersPageState extends State<MovingMarkersPage> {
  late Marker _marker = _markers[_markerIndex];
  late final Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) {
    setState(() {
      _marker = _markers[_markerIndex];
      _markerIndex = (_markerIndex + 1) % _markers.length;
    });
  });
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
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moving Markers')),
      drawer: const MenuDrawer(MovingMarkersPage.route),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(51.5, -0.09),
          initialZoom: 5,
        ),
        children: [
          openStreetMapTileLayer,
          MarkerLayer(markers: [_marker]),
        ],
      ),
    );
  }
}
