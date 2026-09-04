import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/number_of_items_slider.dart';
import 'package:flutter_map_example/widgets/perf_overlay.dart';
import 'package:latlong2/latlong.dart';

const _maxMarkersCount = 20000;
const _londonOrigin = LatLng(51.5074, -0.1278);

/// On this page, [_maxMarkersCount] markers are randomly generated
/// across London, and then you can limit them with a slider
///
/// This way, you can test how map performs under a lot of markers
///
/// The markers are quite expensive - an `Icon` is expensive itself, and adding
/// a `GestureDetector` makes things much slower.
class ManyMarkersPage extends StatefulWidget {
  static const String route = '/many_markers';

  const ManyMarkersPage({super.key});

  @override
  ManyMarkersPageState createState() => ManyMarkersPageState();
}

class ManyMarkersPageState extends State<ManyMarkersPage> {
  final randomGenerator = Random(10);
  late List<Marker> allMarkers = List.generate(
    _maxMarkersCount,
    (_) {
      final angle = randomGenerator.nextDouble() * 2 * pi;
      final distance = randomGenerator.nextDouble() * 0.5;
      final latOffset =
          distance * sin(angle) * (0.7 + randomGenerator.nextDouble() * 0.6);
      final lngOffset =
          distance * cos(angle) * (0.7 + randomGenerator.nextDouble() * 0.6);
      final position = LatLng(
        _londonOrigin.latitude + latOffset,
        _londonOrigin.longitude + lngOffset,
      );

      return Marker(
        point: position,
        child: Icon(
          Icons.location_pin,
          size: 30,
          color: Color.fromARGB(
            255,
            randomGenerator.nextInt(256),
            randomGenerator.nextInt(256),
            randomGenerator.nextInt(256),
          ),
        ),
      );
    },
  );
  int displayedMarkersCount = _maxMarkersCount ~/ 10;

  bool useIcons = true;
  bool useSizeInMeters = false;
  bool optimizeSizeInMeters = true;

  @override
  void initState() {
    super.initState();
    PerfOverlay.showWebUnavailable(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Many Markers')),
      drawer: const MenuDrawer(ManyMarkersPage.route),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds(
                  const LatLng(50, -0.5),
                  const LatLng(53, 0.3),
                ),
              ),
            ),
            children: [
              const PrimaryTileLayer(),
              MarkerLayer(
                markers: allMarkers
                    .take(displayedMarkersCount)
                    .toList(growable: false),
                optimizeDimensionsInMeters: optimizeSizeInMeters,
              ),
            ],
          ),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: Column(
              spacing: 12,
              children: [
                NumberOfItemsSlider(
                  number: displayedMarkersCount,
                  onChanged: (v) => setState(() => displayedMarkersCount = v),
                  maxNumber: _maxMarkersCount,
                  itemDescription: 'Marker',
                ),
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
                    child: IntrinsicHeight(
                      child: Row(
                        spacing: 8,
                        children: [
                          const Tooltip(
                            message: 'Use Icons',
                            child: Icon(Icons.location_on),
                          ),
                          Switch.adaptive(
                            value: useIcons,
                            onChanged: _useIconsToggler,
                          ),
                          const VerticalDivider(),
                          const Tooltip(
                            message: 'Use Radius In Meters',
                            child: Icon(Icons.straighten),
                          ),
                          Switch.adaptive(
                            value: useSizeInMeters,
                            onChanged:
                                useIcons ? null : _useDimensionsInMetersToggler,
                          ),
                          const Tooltip(
                            message: 'Optimise Meters Radius',
                            child: Icon(Icons.speed_rounded),
                          ),
                          Switch.adaptive(
                            value: optimizeSizeInMeters,
                            onChanged: useSizeInMeters && !useIcons
                                ? (v) =>
                                    setState(() => optimizeSizeInMeters = v)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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

  void _useDimensionsInMetersToggler(bool v) {
    allMarkers = allMarkers.map(
      (c) {
        return Marker(
          point: c.point,
          useDimensionsInMeters: v ? const BoxConstraints() : null,
          height: v ? 1000 : 30,
          width: v ? 1000 : 30,
          child: SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(),
              ),
            ),
          ),
        );
      },
    ).toList(growable: false);
    useSizeInMeters = v;
    setState(() {});
  }

  void _useIconsToggler(bool v) {
    allMarkers = allMarkers
        .map(
          v
              ? (c) => Marker(
                    point: c.point,
                    child: Icon(
                      Icons.location_pin,
                      size: 30,
                      color: Color.fromARGB(
                        255,
                        randomGenerator.nextInt(256),
                        randomGenerator.nextInt(256),
                        randomGenerator.nextInt(256),
                      ),
                    ),
                  )
              : (c) => Marker(
                    point: c.point,
                    useDimensionsInMeters:
                        useSizeInMeters ? const BoxConstraints() : null,
                    height: useSizeInMeters ? 1000 : 30,
                    width: useSizeInMeters ? 1000 : 30,
                    child: SizedBox.expand(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(),
                        ),
                      ),
                    ),
                  ),
        )
        .toList(growable: false);
    useIcons = v;
    setState(() {});
  }
}
