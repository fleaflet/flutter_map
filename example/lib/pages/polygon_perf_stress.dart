import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/show_no_web_perf_overlay_snackbar.dart';
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
  static const bool _initialUsePerformantDrawing = true;
  bool usePerformantDrawing = _initialUsePerformantDrawing;
  static const bool _initialUseThickOutlines = false;
  bool useThickOutlines = _initialUseThickOutlines;

  late Future<GeoJsonParser> geoJsonParser = loadPolygonsFromGeoJson();

  @override
  void initState() {
    super.initState();
    showNoWebPerfOverlaySnackbar(context);
  }

  @override
  void dispose() {
    geoJsonParser.ignore();
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
                future: geoJsonParser,
                builder: (context, geoJsonParser) =>
                    geoJsonParser.connectionState != ConnectionState.done ||
                            geoJsonParser.data == null
                        ? const SizedBox.shrink()
                        : PolygonLayer(
                            polygons: geoJsonParser.data!.polygons,
                            performantRendering: usePerformantDrawing,
                            simplificationTolerance: simplificationTolerance,
                          ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: Column(
              children: [
                SimplificationToleranceSlider(
                  initialTolerance: _initialSimplificationTolerance,
                  onChangedTolerance: (v) =>
                      setState(() => simplificationTolerance = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _LabelledSwitch(
                      tooltipMessage: 'Performant Drawing',
                      icon: const Icon(Icons.speed_rounded),
                      value: usePerformantDrawing,
                      onChanged: (v) =>
                          setState(() => usePerformantDrawing = v),
                    ),
                    const SizedBox(width: 12),
                    _LabelledSwitch(
                      tooltipMessage: 'Thick Outlines',
                      icon: const Icon(Icons.line_weight_rounded),
                      value: useThickOutlines,
                      onChanged: (v) async {
                        setState(() => useThickOutlines = v);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                SizedBox.square(
                                  dimension: 16,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Loading GeoJson polygons...'),
                              ],
                            ),
                          ),
                        );
                        await (geoJsonParser = loadPolygonsFromGeoJson());
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).clearSnackBars();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
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

  Future<GeoJsonParser> loadPolygonsFromGeoJson() async {
    const filePath = 'assets/138k-polygon-points.geojson.noformat';

    return rootBundle.loadString(filePath).then(
          (geoJson) => compute(
            (msg) => GeoJsonParser(
              defaultPolygonBorderStroke: msg.useThickOutlines ? 15 : 1,
              defaultPolygonBorderColor: Colors.black.withOpacity(0.5),
              defaultPolygonFillColor: Colors.amber.withOpacity(0.5),
            )..parseGeoJsonAsString(msg.geoJson),
            (geoJson: geoJson, useThickOutlines: useThickOutlines),
          ),
        );
  }
}

class _LabelledSwitch extends StatelessWidget {
  const _LabelledSwitch({
    required this.tooltipMessage,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String tooltipMessage;
  final Icon icon;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
          child: Row(
            children: [
              Tooltip(message: tooltipMessage, child: icon),
              const SizedBox(width: 8),
              Switch.adaptive(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
