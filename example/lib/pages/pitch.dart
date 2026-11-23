import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class PitchPage extends StatefulWidget {
  static const String route = '/pitch';

  const PitchPage({super.key});

  @override
  State<PitchPage> createState() => _PitchPageState();
}

class _PitchPageState extends State<PitchPage> {
  static const _center = LatLng(51.5, -0.09);

  final _mapController = MapController();
  double _pitch = 45;
  double _rotation = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pitch')),
      drawer: const MenuDrawer(PitchPage.route),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                const Text(
                  'Markers and labels face the viewer; tiles, polygons and '
                  'polylines lie on the ground. Far ground uses coarser '
                  'tiles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text('Pitch ${_pitch.round()}°'),
                    ),
                    Expanded(
                      child: Slider(
                        value: _pitch,
                        max: MapOptions.pitchLimit,
                        onChanged: (value) {
                          setState(() => _pitch = value);
                          _mapController.pitch(value);
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text('Rotation ${_rotation.round()}°'),
                    ),
                    Expanded(
                      child: Slider(
                        value: _rotation,
                        min: -180,
                        max: 180,
                        onChanged: (value) {
                          setState(() => _rotation = value);
                          _mapController.rotate(value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 14,
                initialPitch: _pitch,
                maxPitch: MapOptions.pitchLimit,
                onMapEvent: (event) {
                  if (event.camera.pitch != _pitch ||
                      event.camera.rotation != _rotation) {
                    setState(() {
                      _pitch = event.camera.pitch;
                      _rotation =
                          event.camera.rotation.remainder(360).clamp(-180, 180);
                    });
                  }
                },
              ),
              children: [
                const PrimaryTileLayer(),
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: const [
                        LatLng(51.508, -0.11),
                        LatLng(51.508, -0.095),
                        LatLng(51.500, -0.095),
                        LatLng(51.500, -0.11),
                      ],
                      color: Colors.purple.withAlpha(96),
                      borderColor: Colors.purple,
                      borderStrokeWidth: 3,
                      label: 'Polygon',
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: const [
                        LatLng(51.490, -0.12),
                        LatLng(51.500, -0.09),
                        LatLng(51.515, -0.08),
                        LatLng(51.530, -0.07),
                      ],
                      strokeWidth: 6,
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(
                  rotate: true,
                  markers: [
                    for (final point in const [
                      _center,
                      LatLng(51.52, -0.10),
                      LatLng(51.535, -0.075),
                    ])
                      Marker(
                        point: point,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_pin,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
