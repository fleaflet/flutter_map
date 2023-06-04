import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class PolylinePage extends StatefulWidget {
  static const String route = 'polyline';

  const PolylinePage({Key? key}) : super(key: key);

  @override
  State<PolylinePage> createState() => _PolylinePageState();
}

class _PolylinePageState extends State<PolylinePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polylines')),
      drawer: buildDrawer(context, PolylinePage.route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text('Polylines'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: const LatLng(51.5, -0.09),
                  zoom: 5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          const LatLng(51.5, -0.09),
                          const LatLng(53.3498, -6.2603),
                          const LatLng(48.8566, 2.3522),
                        ],
                        strokeWidth: 4,
                        color: Colors.purple,
                      ),
                      Polyline(
                        points: [
                          const LatLng(55.5, -0.09),
                          const LatLng(54.3498, -6.2603),
                          const LatLng(52.8566, 2.3522),
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
                          const LatLng(50.5, -0.09),
                          const LatLng(51.3498, 6.2603),
                          const LatLng(53.8566, 2.3522),
                        ],
                        strokeWidth: 20,
                        color: Colors.blue.withOpacity(0.6),
                        borderStrokeWidth: 20,
                        borderColor: Colors.red.withOpacity(0.4),
                      ),
                      Polyline(
                        points: [
                          const LatLng(50.2, -0.08),
                          const LatLng(51.2498, -10.2603),
                          const LatLng(54.8566, -9.3522),
                        ],
                        strokeWidth: 20,
                        color: Colors.black.withOpacity(0.2),
                        borderStrokeWidth: 20,
                        borderColor: Colors.white30,
                      ),
                      Polyline(
                        points: [
                          const LatLng(49.1, -0.06),
                          const LatLng(52.15, -1.4),
                          const LatLng(55.5, 0.8),
                        ],
                        strokeWidth: 10,
                        color: Colors.yellow,
                        borderStrokeWidth: 10,
                        borderColor: Colors.blue.withOpacity(0.5),
                      ),
                      Polyline(
                        points: [
                          const LatLng(48.1, -0.03),
                          const LatLng(50.5, -7.8),
                          const LatLng(56.5, 0.4),
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
            ),
          ],
        ),
      ),
    );
  }
}
