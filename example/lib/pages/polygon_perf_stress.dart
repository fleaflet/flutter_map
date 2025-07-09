import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/perf_overlay.dart';
import 'package:flutter_map_example/widgets/simplification_tolerance_slider.dart';
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

  late final polygonsPoints = unpackPolygonGeometries().toList();
  late Future<List<Polygon>> polygons = generatePolygonsFromPoints();

  Future<List<Polygon>> generatePolygonsFromPoints() async =>
      (await polygonsPoints)
          .map(
            (points) => Polygon(
              points: points,
              borderStrokeWidth: borderThickness,
              borderColor: Colors.black.withAlpha(128),
              color: Colors.orange[700]!.withAlpha(191),
            ),
          )
          .toList(growable: false);

  @override
  void initState() {
    super.initState();
    PerfOverlay.showWebUnavailable(context);
  }

  @override
  void dispose() {
    polygonsPoints.ignore();
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
                future: polygons,
                builder: (context, polygons) => polygons.data == null
                    ? const SizedBox.shrink()
                    : PolygonLayer(
                        polygons: polygons.data!,
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
                                    onSelected: (selected) {
                                      if (!selected) return;
                                      setState(() {
                                        borderThickness = thickness.toDouble();
                                        polygons = generatePolygonsFromPoints();
                                      });
                                    },
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

  Stream<List<LatLng>> unpackPolygonGeometries() async* {
    const filePath = 'assets/polygon-stress-test-data.bin';

    // See packing algorithm & README for details. Determined when packing.
    const scaleFactor = 8388608;
    const bytesPerNum = 4;

    final bytes = await rootBundle.load(filePath);

    int ptr = 0;
    while (ptr < bytes.lengthInBytes) {
      final numBytesToRead = bytes.getUint32(ptr);
      ptr += 4;

      yield List.generate(
        numBytesToRead ~/ 2 ~/ bytesPerNum,
        (i) => LatLng(
          bytes.getInt32(ptr + (i * 8)) / scaleFactor,
          bytes.getInt32(ptr + (i * 8) + 4) / scaleFactor,
        ),
        growable: false,
      );

      ptr += numBytesToRead;
    }
  }
}
