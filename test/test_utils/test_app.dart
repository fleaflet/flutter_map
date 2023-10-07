import 'package:flutter/material.dart';
import 'package:flutter_map/src/layer/circle_layer.dart';
import 'package:flutter_map/src/layer/marker_layer.dart';
import 'package:flutter_map/src/layer/polygon_layer/polygon_layer.dart';
import 'package:flutter_map/src/layer/polyline_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/map/controller/map_controller.dart';
import 'package:flutter_map/src/map/options/options.dart';
import 'package:flutter_map/src/map/widget.dart';
import 'package:latlong2/latlong.dart';

import 'test_tile_provider.dart';

class TestApp extends StatelessWidget {
  const TestApp({
    super.key,
    this.controller,
    this.markers = const [],
    this.polygons = const [],
    this.polylines = const [],
    this.circles = const [],
  });

  final MapController? controller;
  final List<Marker> markers;
  final List<Polygon> polygons;
  final List<Polyline> polylines;
  final List<CircleMarker> circles;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          // Ensure that map is always of the same size
          child: SizedBox(
            width: 200,
            height: 200,
            child: FlutterMap(
              mapController: controller,
              options: const MapOptions(
                initialCenter: LatLng(45.5231, -122.6765),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  tileProvider: TestTileProvider(),
                ),
                if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
                if (circles.isNotEmpty) CircleLayer(circles: circles),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
