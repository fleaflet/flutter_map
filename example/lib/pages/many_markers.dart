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
  late final allMarkers = List.generate(
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
        width: 30,
        height: 30,
        child: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tapped existing marker (${position.latitude}, '
                '${position.longitude})',
              ),
              duration: const Duration(seconds: 1),
              showCloseIcon: true,
            ),
          ),
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
        ),
      );
    },
  );
  int displayedMarkersCount = _maxMarkersCount ~/ 10;

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
              openStreetMapTileLayer,
              MarkerLayer(
                markers: allMarkers
                    .take(displayedMarkersCount)
                    .toList(growable: false),
              ),
            ],
          ),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: NumberOfItemsSlider(
              number: displayedMarkersCount,
              onChanged: (v) => setState(() => displayedMarkersCount = v),
              maxNumber: _maxMarkersCount,
              itemDescription: 'Marker',
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
