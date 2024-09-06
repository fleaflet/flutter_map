import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/show_no_web_perf_overlay_snackbar.dart';
import 'package:flutter_map_example/widgets/simplification_tolerance_slider.dart';
import 'package:latlong2/latlong.dart';

class PolylinePerfStressPage extends StatefulWidget {
  static const String route = '/polyline_perf_stress';

  const PolylinePerfStressPage({super.key});

  @override
  State<PolylinePerfStressPage> createState() => _PolylinePerfStressPageState();
}

class _PolylinePerfStressPageState extends State<PolylinePerfStressPage> {
  double simplificationTolerance = 0.3;

  final _randomWalk = [const LatLng(44.861294, 13.845086)];

  @override
  void initState() {
    super.initState();

    showNoWebPerfOverlaySnackbar(context);

    final random = Random(1234);
    for (int i = 1; i < 300000; i++) {
      final lat = (random.nextDouble() - 0.5) * 0.001;
      final lon = (random.nextDouble() - 0.6) * 0.001;
      _randomWalk.add(
        LatLng(
          _randomWalk[i - 1].latitude + lat,
          _randomWalk[i - 1].longitude + lon,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polyline Stress Test')),
      drawer: const MenuDrawer(PolylinePerfStressPage.route),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(_randomWalk),
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
              PolylineLayer(
                simplificationTolerance: simplificationTolerance,
                polylines: [
                  Polyline(
                    points: _randomWalk,
                    strokeWidth: 3,
                    color: Colors.deepOrange,
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: SimplificationToleranceSlider(
              tolerance: simplificationTolerance,
              onChanged: (v) => setState(() => simplificationTolerance = v),
            ),
          ),
          if (!kIsWeb)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: PerformanceOverlay.allEnabled(),
            ),
        ],
      ),
    );
  }
}
