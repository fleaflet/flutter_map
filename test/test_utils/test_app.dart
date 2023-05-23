import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
          // ensure that map is always of the same size
          child: SizedBox(
            width: 200,
            height: 200,
            child: FlutterMap(
              mapController: controller,
              options: MapOptions(
                center: const LatLng(45.5231, -122.6765),
                zoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
