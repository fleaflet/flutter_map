import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';

class PolylinePage extends StatefulWidget {
  static const String route = '/polyline';

  const PolylinePage({super.key});

  @override
  State<PolylinePage> createState() => _PolylinePageState();
}

class _PolylinePageState extends State<PolylinePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polylines')),
      drawer: const MenuDrawer(PolylinePage.route),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: (lat: 51.5, lon: 0.09),
          initialZoom: 5,
        ),
        children: [
          openStreetMapTileLayer,
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  const (lat: 51.5, lon: 0.09),
                  const (lat: 53.3498, lon: 6.2603),
                  const (lat: 48.8566, lon: 2.3522),
                ],
                strokeWidth: 4,
                color: Colors.purple,
              ),
              Polyline(
                points: [
                  const (lat: 55.5, lon: 0.09),
                  const (lat: 54.3498, lon: 6.2603),
                  const (lat: 52.8566, lon: 2.3522),
                ],
                strokeWidth: 4,
                gradientColors: [
                  const Color(0xffE40203),
                  const Color(0xffFEED00),
                  const Color(0xff007E2D),
                ],
              ),
              Polyline(
                points: [
                  const (lat: 50.5, lon: 0.09),
                  const (lat: 51.3498, lon: 6.2603),
                  const (lat: 53.8566, lon: 2.3522),
                ],
                strokeWidth: 20,
                color: Colors.blue.withOpacity(0.6),
                borderStrokeWidth: 20,
                borderColor: Colors.red.withOpacity(0.4),
              ),
              Polyline(
                points: [
                  const (lat: 50.2, lon: 0.08),
                  const (lat: 51.2498, lon: 10.2603),
                  const (lat: 54.8566, lon: 9.3522),
                ],
                strokeWidth: 20,
                color: Colors.black.withOpacity(0.2),
                borderStrokeWidth: 20,
                borderColor: Colors.white30,
              ),
              Polyline(
                points: [
                  const (lat: 49.1, lon: 0.06),
                  const (lat: 52.15, lon: 1.4),
                  const (lat: 55.5, lon: 0.8),
                ],
                strokeWidth: 10,
                color: Colors.yellow,
                borderStrokeWidth: 10,
                borderColor: Colors.blue.withOpacity(0.5),
              ),
              Polyline(
                points: [
                  const (lat: 48.1, lon: 0.03),
                  const (lat: 50.5, lon: 7.8),
                  const (lat: 56.5, lon: 0.4),
                ],
                strokeWidth: 10,
                color: Colors.amber,
                borderStrokeWidth: 10,
                borderColor: Colors.blue.withOpacity(0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
