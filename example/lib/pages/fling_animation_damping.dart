import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class FlingAnimationDampingPage extends StatefulWidget {
  static const String route = '/fling_animation_damping';

  const FlingAnimationDampingPage({super.key});

  @override
  State<FlingAnimationDampingPage> createState() =>
      _FlingAnimationDampingPageState();
}

class _FlingAnimationDampingPageState extends State<FlingAnimationDampingPage> {
  double _dampingRatio = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fling Animation Damping')),
      drawer: const MenuDrawer(FlingAnimationDampingPage.route),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Damping Ratio: ${_dampingRatio.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Drag the map and release to see the fling animation. '
                  'Lower values = less momentum, stops quicker. '
                  'Higher values = more momentum, bouncier feel. ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Damped (1)'),
                    Expanded(
                      child: Slider(
                        value: _dampingRatio,
                        min: 1,
                        max: 10,
                        divisions: 19,
                        label: _dampingRatio.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _dampingRatio = value;
                          });
                        },
                      ),
                    ),
                    const Text('Damped (10)'),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() => _dampingRatio = 1),
                      child: const Text('Very Damped (1)'),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => _dampingRatio = 2),
                      child: const Text('Damped (2)'),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => _dampingRatio = 5),
                      child: const Text('Default (5)'),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => _dampingRatio = 7),
                      child: const Text('Bouncy (4)'),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => _dampingRatio = 10),
                      child: const Text('Very Bouncy (10)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(51.5, -0.09),
                initialZoom: 11,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all,
                  flingAnimationDampingRatio: _dampingRatio,
                ),
              ),
              children: [
                openStreetMapTileLayer,
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Drag and release to see the fling effect!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
