import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/simplification_tolerance_slider.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:latlong2/latlong.dart';

class PolygonPerfStressPage extends StatefulWidget {
  static const String route = '/polygon_perf_stress';

  const PolygonPerfStressPage({super.key});

  @override
  State<PolygonPerfStressPage> createState() => _PolygonPerfStressPageState();
}

class _PolygonPerfStressPageState extends State<PolygonPerfStressPage> {
  static const double _initialSimplificationTolerance = 0.5;
  double simplificationTolerance = _initialSimplificationTolerance;

  late final geoJsonLoader =
      rootBundle.loadString('assets/138k-polygon-points.geojson.noformat').then(
            (geoJson) => compute(
              (geoJson) => GeoJsonParser()..parseGeoJsonAsString(geoJson),
              geoJson,
            ),
          );

  @override
  void dispose() {
    geoJsonLoader.ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polygon Stress Test')),
      drawer: const MenuDrawer(PolygonPerfStressPage.route),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds(
                  const LatLng(58.93864, 47.757597),
                  const LatLng(58.806666, 47.848959),
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
              FutureBuilder(
                future: geoJsonLoader,
                builder: (context, geoJsonParser) =>
                    geoJsonParser.connectionState != ConnectionState.done ||
                            geoJsonParser.data == null
                        ? const SizedBox.shrink()
                        : PolygonLayer(
                            simplificationTolerance: simplificationTolerance,
                            polygons: geoJsonParser.data!.polygons,
                          ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: SimplificationToleranceSlider(
              initialTolerance: _initialSimplificationTolerance,
              onChangedTolerance: (v) =>
                  setState(() => simplificationTolerance = v),
            ),
          ),
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
