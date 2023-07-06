import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class FallbackUrlPage extends StatelessWidget {
  final String route;
  final TileLayer tileLayer;
  final String title;
  final String description;
  final double zoom;
  final double? maxZoom;
  final double? minZoom;
  final LatLng center;

  const FallbackUrlPage({
    Key? key,
    required this.route,
    required this.tileLayer,
    required this.title,
    required this.description,
    required this.center,
    this.zoom = 13,
    this.maxZoom,
    this.minZoom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: buildDrawer(context, route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(description),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: zoom,
                  maxZoom: maxZoom,
                  minZoom: minZoom,
                ),
                children: [tileLayer],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
