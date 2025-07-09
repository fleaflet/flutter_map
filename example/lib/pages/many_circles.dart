import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/number_of_items_slider.dart';
import 'package:flutter_map_example/widgets/perf_overlay.dart';
import 'package:latlong2/latlong.dart';

const _maxCirclesCount = 30000;

/// On this page, [_maxCirclesCount] circles are randomly generated
/// across europe, and then you can limit them with a slider
///
/// This way, you can test how map performs under a lot of circles
class ManyCirclesPage extends StatefulWidget {
  static const String route = '/many_circles';

  const ManyCirclesPage({super.key});

  @override
  State<ManyCirclesPage> createState() => _ManyCirclesPageState();
}

class _ManyCirclesPageState extends State<ManyCirclesPage> {
  static double doubleInRange(Random source, num start, num end) =>
      source.nextDouble() * (end - start) + start;

  final randomGenerator = Random();
  late List<CircleMarker> allCircles = List.generate(
    _maxCirclesCount,
    (i) => CircleMarker(
      point: LatLng(
        doubleInRange(randomGenerator, 37, 55),
        doubleInRange(randomGenerator, -9, 30),
      ),
      color: HSLColor.fromAHSL(
        1,
        i % 360,
        1,
        doubleInRange(randomGenerator, 0.3, 0.7),
      ).toColor(),
      radius: 5,
      useRadiusInMeter: false,
      borderStrokeWidth: 0,
      borderColor: Colors.black,
    ),
    growable: false,
  );
  int displayedCirclesCount = _maxCirclesCount ~/ 10;

  bool useBorders = false;
  bool useRadiusInMeters = false;
  bool optimizeRadiusInMeters = true;

  @override
  void initState() {
    super.initState();
    PerfOverlay.showWebUnavailable(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Many Circles')),
      drawer: const MenuDrawer(ManyCirclesPage.route),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds(
                  const LatLng(55, -9),
                  const LatLng(37, 30),
                ),
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 88,
                  bottom: 192,
                ),
              ),
            ),
            children: [
              openStreetMapTileLayer,
              CircleLayer(
                circles: allCircles
                    .take(displayedCirclesCount)
                    .toList(growable: false),
                optimizeRadiusInMeters: optimizeRadiusInMeters,
              ),
            ],
          ),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: RepaintBoundary(
              child: Column(
                children: [
                  NumberOfItemsSlider(
                    number: displayedCirclesCount,
                    onChanged: (v) => setState(() => displayedCirclesCount = v),
                    maxNumber: _maxCirclesCount,
                    itemDescription: 'Circle',
                  ),
                  const SizedBox(height: 12),
                  UnconstrainedBox(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          const Tooltip(
                            message: 'Use Borders',
                            child: Icon(Icons.circle_outlined),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: useBorders,
                            onChanged: (v) {
                              allCircles = allCircles
                                  .map(
                                    (c) => CircleMarker(
                                      point: c.point,
                                      radius: c.radius,
                                      color: c.color,
                                      useRadiusInMeter: c.useRadiusInMeter,
                                      borderColor: c.borderColor,
                                      borderStrokeWidth: v ? 5 : 0,
                                    ),
                                  )
                                  .toList(growable: false);
                              useBorders = v;
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 16),
                          const Tooltip(
                            message: 'Use Radius In Meters',
                            child: Icon(Icons.straighten),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: useRadiusInMeters,
                            onChanged: (v) {
                              allCircles = allCircles
                                  .map(
                                    (c) => CircleMarker(
                                      point: c.point,
                                      radius: v ? 25000 : 5,
                                      color: c.color,
                                      useRadiusInMeter: v,
                                      borderColor: c.borderColor,
                                      borderStrokeWidth: c.borderStrokeWidth,
                                    ),
                                  )
                                  .toList(growable: false);
                              useRadiusInMeters = v;
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 16),
                          const Tooltip(
                            message: 'Optimise Meters Radius',
                            child: Icon(Icons.speed_rounded),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: optimizeRadiusInMeters,
                            onChanged: useRadiusInMeters
                                ? (v) =>
                                    setState(() => optimizeRadiusInMeters = v)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!kIsWeb)
            const Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: PerfOverlay(),
            ),
        ],
      ),
    );
  }
}
