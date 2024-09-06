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
  double simplificationTolerance = 0.3;
  bool useAltRendering = true;
  double borderThickness = 1;

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
                  top: 145,
                  bottom: 175,
                ),
              ),
            ),
            children: [
              openStreetMapTileLayer,
              FutureBuilder(
                future: geoJsonParser,
                builder: (context, geoJsonParser) => geoJsonParser.data == null
                    ? const SizedBox.shrink()
                    : PolygonLayer(
                        polygons: geoJsonParser.data!.polygons,
                        useAltRendering: useAltRendering,
                        simplificationTolerance: simplificationTolerance,
                      ),
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
                  SimplificationToleranceSlider(
                    tolerance: simplificationTolerance,
                    onChanged: (v) =>
                        setState(() => simplificationTolerance = v),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
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
                                message: 'Use Alternative Rendering Pathway',
                                child: Icon(Icons.speed_rounded),
                              ),
                              const SizedBox(width: 8),
                              Switch.adaptive(
                                value: useAltRendering,
                                onChanged: (v) =>
                                    setState(() => useAltRendering = v),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Not ideal that we have to re-parse the GeoJson every
                      // time this is changed, but the library gives no easy
                      // way to change it after
                      UnconstrainedBox(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              const Tooltip(
                                message: 'Border Thickness',
                                child: Icon(Icons.line_weight_rounded),
                              ),
                              if (MediaQuery.devicePixelRatioOf(context) > 1 &&
                                  borderThickness == 1)
                                const Tooltip(
                                  message: 'Screen has a high DPR: 1lp > 1dp',
                                  child: Icon(
                                    Icons.warning,
                                    color: Colors.amber,
                                  ),
                                ),
                              const SizedBox.shrink(),
                              ...List.generate(
                                4,
                                (i) {
                                  final thickness = i * i;
                                  return ChoiceChip(
                                    label: Text(
                                      thickness == 0
                                          ? 'None'
                                          : '${thickness}px',
                                    ),
                                    selected: borderThickness == thickness,
                                    shape: const StadiumBorder(),
                                    onSelected: (selected) => reloadGeoJson(
                                      context: context,
                                      selected: selected,
                                      thickness: thickness,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

  Future<void> reloadGeoJson({
    required BuildContext context,
    required bool selected,
    required num thickness,
  }) async {
    if (!selected) return;
    setState(() => borderThickness = thickness.toDouble());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(
                  Colors.white,
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
  }

  Future<GeoJsonParser> loadPolygonsFromGeoJson() async {
    const filePath = 'assets/138k-polygon-points.geojson.noformat';

    return rootBundle.loadString(filePath).then(
          (geoJson) => compute(
            (msg) => GeoJsonParser(
              defaultPolygonBorderStroke: msg.borderThickness,
              defaultPolygonBorderColor: Colors.black.withOpacity(0.5),
              defaultPolygonFillColor: Colors.orange[700]!.withOpacity(0.75),
            )..parseGeoJsonAsString(msg.geoJson),
            (geoJson: geoJson, borderThickness: borderThickness),
          ),
        );
  }
}
