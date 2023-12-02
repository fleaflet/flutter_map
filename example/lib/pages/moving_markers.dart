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
  Marker? _marker;
  late final Timer _timer;
  int _markerIndex = 0;

  static const _markers = [
    Marker(
      width: 80,
      height: 80,
      point: (lat: 51.5, lon: 0.09),
      child: FlutterLogo(),
    ),
    Marker(
      width: 80,
      height: 80,
      point: (lat: 53.3498, lon: 6.2603),
      child: FlutterLogo(),
    ),
    Marker(
      width: 80,
      height: 80,
      point: (lat: 48.8566, lon: 2.3522),
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
      appBar: AppBar(title: const Text('Moving Markers')),
      drawer: const MenuDrawer(MovingMarkersPage.route),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: (lat: 51.5, lon: 0.09),
          initialZoom: 5,
        ),
        children: [
          openStreetMapTileLayer,
          MarkerLayer(markers: [_marker!]),
        ],
      ),
    );
  }
}
