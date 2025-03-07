import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

/// Example dedicated to [PolygonLayer.invertedFill]
class InvertedPolygonsPage extends StatefulWidget {
  static const String route = '/inverted_polygons';

  const InvertedPolygonsPage({super.key});

  @override
  State<InvertedPolygonsPage> createState() => _InvertedPolygonsPageState();
}

class _InvertedPolygonsPageState extends State<InvertedPolygonsPage> {
  final LayerHitNotifier<String> _hitNotifier = ValueNotifier(null);

  final _customMarkers = <Marker>[];

  Marker _buildPin(LatLng point) => Marker(
        point: point,
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tapped existing marker'),
              duration: Duration(seconds: 1),
              showCloseIcon: true,
            ),
          ),
          child: const Icon(Icons.location_pin, color: Colors.red),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced polygons')),
      drawer: const MenuDrawer(InvertedPolygonsPage.route),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(45.5, 2),
              initialZoom: 0,
              initialRotation: 0,
              onTap: (_, p) => setState(() => _customMarkers.add(_buildPin(p))),
            ),
            children: [
              openStreetMapTileLayer,
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_hitNotifier.value!.hitValues.join(', ')),
                    duration: const Duration(seconds: 1),
                    showCloseIcon: true,
                  ),
                ),
                child: PolygonLayer<String>(
                  hitNotifier: _hitNotifier,
                  simplificationTolerance: 0,
                  useAltRendering: false,
                  drawLabelsLast: false,
                  invertedFill: const Color(0x20FF0000),
                  polygons: [
                    Polygon<String>(
                      rotateLabel: false,
                      borderColor: const Color(0xFF0000FF),
                      borderStrokeWidth: 3,
                      color: const Color(0x4000FFFF),
                      hitValue: 'France',
                      points: const [
                        // France
                        // Calais 50° 56′ 53″ nord, 1° 51′ 23″ est
                        LatLng(50.948056, 1.856389),
                        // Brest 48° 23′ 27″ nord, 4° 29′ 08″ ouest
                        LatLng(48.390833, -4.485556),
                        // Biarritz 43° 28′ 54″ nord, 1° 33′ 22″ ouest
                        LatLng(43.481667, -1.556111),
                        // Perpignan 42° 41′ 55″ nord, 2° 53′ 44″ est
                        LatLng(42.698611, 2.895556),
                        // Menton 43° 46′ 33″ nord, 7° 30′ 10″ est
                        LatLng(43.775833, 7.502778),
                        // Strasbourg 48° 34′ 24″ nord, 7° 45′ 08″ est
                        LatLng(48.573333, 7.752222),
                      ],
                    ),
                    Polygon<String>(
                      rotateLabel: false,
                      borderColor: const Color(0xFFFF0000),
                      borderStrokeWidth: 3,
                      pattern: StrokePattern.dashed(segments: [20, 10, 10, 10]),
                      color: null,
                      hitValue: 'South America',
                      points: const [
                        // South America
                        // Ushuaia 54° 48′ 35″ sud, 68° 18′ 50″ ouest
                        LatLng(-54.809722, -68.313889),
                        // Fortaleza 3° 43′ 01″ sud, 38° 32′ 34″ ouest
                        LatLng(-3.716944, -38.542778),
                        // Panama 8° 58′ nord, 79° 32′ ouest
                        LatLng(8.966667, -79.533333),
                        // Quito 0° 14′ 18″ sud, 78° 31′ 02″ ouest
                        LatLng(-0.238333, -78.517222),
                      ],
                    ),
                    Polygon<String>(
                      rotateLabel: false,
                      borderColor: const Color(0xFF00FF00),
                      borderStrokeWidth: 3,
                      pattern: const StrokePattern.dotted(spacingFactor: 3),
                      color: const Color(0x20000000),
                      hitValue: 'Across the border',
                      points: const [
                        // Across the border
                        LatLng(26.69, -137.39),
                        LatLng(37.91, 150.65),
                        LatLng(-7.67, 151.20),
                        LatLng(-7.32, -140.78),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
