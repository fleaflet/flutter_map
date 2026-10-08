// Layer-level CPU benchmarks, used to validate performance work.
//
// Run with:
//   flutter test benchmark/feature_layer_benchmark_test.dart --plain-name=benchmark -r expanded
//
// Numbers are JIT/debug-mode and only meaningful *relative* to each other
// (before/after a change on the same machine). Each scenario warms up, then
// times repeated pumps while the camera pans, and reports the best repetition
// (min) to reduce GC/scheduling noise.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/misc/offsets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

const _center = LatLng(-37.8136, 144.9631);

List<LatLng> _randomWalk(
  math.Random rng,
  LatLng start,
  int count, [
  double stepDeg = 0.0004,
]) {
  final points = <LatLng>[];
  var lat = start.latitude;
  var lng = start.longitude;
  for (var i = 0; i < count; i++) {
    lat += (rng.nextDouble() - 0.5) * stepDeg;
    lng += (rng.nextDouble() - 0.5) * stepDeg;
    points.add(LatLng(lat, lng));
  }
  return points;
}

LatLng _randomNear(math.Random rng, LatLng base, double spreadDeg) => LatLng(
      base.latitude + (rng.nextDouble() - 0.5) * spreadDeg,
      base.longitude + (rng.nextDouble() - 0.5) * spreadDeg,
    );

Widget _app(MapController controller, double zoom, List<Widget> layers) =>
    MaterialApp(
      home: FlutterMap(
        mapController: controller,
        options: MapOptions(initialCenter: _center, initialZoom: zoom),
        children: layers,
      ),
    );

/// Pans the camera back and forth and reports the best-rep average frame
/// build+paint time, in microseconds.
Future<double> _benchPans(
  WidgetTester tester,
  MapController controller,
  double zoom, {
  int reps = 3,
  int framesPerRep = 40,
}) async {
  // Warm-up (fills projection/simplification caches, JIT).
  for (var i = 0; i < 10; i++) {
    controller.move(
      LatLng(_center.latitude, _center.longitude + 0.00001 * (i + 1)),
      zoom,
    );
    await tester.pump();
  }

  var best = double.infinity;
  for (var rep = 0; rep < reps; rep++) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < framesPerRep; i++) {
      // Small alternating pan, never repeating the previous camera.
      controller.move(
        LatLng(
          _center.latitude + 0.0001 * (i % 7),
          _center.longitude + 0.0001 * (i % 11) + 0.000001 * i,
        ),
        zoom,
      );
      await tester.pump();
    }
    sw.stop();
    final perFrame = sw.elapsedMicroseconds / framesPerRep;
    if (perFrame < best) best = perFrame;
  }
  return best;
}

void main() {
  testWidgets('benchmark: polylines pan (all visible)', (tester) async {
    final rng = math.Random(42);
    final polylines = [
      for (var i = 0; i < 600; i++)
        Polyline<Object>(
          points: _randomWalk(rng, _randomNear(rng, _center, 0.02), 60),
          strokeWidth: 2,
          color: Colors.blue,
        ),
    ];
    final controller = MapController();
    // Zoom 13: ~0.05° viewport, the 0.02° spread keeps everything visible.
    await tester.pumpWidget(
      _app(controller, 13, [PolylineLayer(polylines: polylines)]),
    );
    final us = await _benchPans(tester, controller, 13);
    debugPrint('RESULT polylines_pan_all_visible: '
        '${us.toStringAsFixed(0)} us/frame');
  });

  testWidgets('benchmark: polylines pan (mostly culled)', (tester) async {
    final rng = math.Random(42);
    final polylines = [
      for (var i = 0; i < 600; i++)
        Polyline<Object>(
          points: _randomWalk(rng, _randomNear(rng, _center, 0.5), 60),
          strokeWidth: 2,
          color: Colors.blue,
        ),
    ];
    final controller = MapController();
    // Zoom 16: viewport much smaller than the 0.5° spread.
    await tester.pumpWidget(
      _app(controller, 16, [PolylineLayer(polylines: polylines)]),
    );
    final us = await _benchPans(tester, controller, 16);
    debugPrint('RESULT polylines_pan_mostly_culled: '
        '${us.toStringAsFixed(0)} us/frame');
  });

  testWidgets('benchmark: polygons with holes pan', (tester) async {
    final rng = math.Random(7);
    final polygons = [
      for (var i = 0; i < 200; i++)
        () {
          final base = _randomNear(rng, _center, 0.02);
          return Polygon<Object>(
            points: _randomWalk(rng, base, 40),
            holePointsList: [
              for (var h = 0; h < 3; h++)
                _randomWalk(rng, _randomNear(rng, base, 0.001), 20, 0.0001),
            ],
            color: Colors.green.withValues(alpha: 0.5),
          );
        }(),
    ];
    final controller = MapController();
    await tester.pumpWidget(
      _app(controller, 13, [PolygonLayer(polygons: polygons)]),
    );
    final us = await _benchPans(tester, controller, 13);
    debugPrint('RESULT polygons_holes_pan: ${us.toStringAsFixed(0)} us/frame');
  });

  testWidgets('benchmark: markers pan', (tester) async {
    final rng = math.Random(3);
    final markers = [
      for (var i = 0; i < 3000; i++)
        Marker(
          point: _randomNear(rng, _center, 0.05),
          width: 20,
          height: 20,
          child: const SizedBox.shrink(),
        ),
    ];
    final controller = MapController();
    await tester.pumpWidget(
      _app(controller, 14, [MarkerLayer(markers: markers)]),
    );
    final us = await _benchPans(tester, controller, 14);
    debugPrint('RESULT markers_pan: ${us.toStringAsFixed(0)} us/frame');
  });

  testWidgets('benchmark: markers pan (mostly culled)', (tester) async {
    final rng = math.Random(3);
    final markers = [
      for (var i = 0; i < 10000; i++)
        Marker(
          point: _randomNear(rng, _center, 1),
          width: 20,
          height: 20,
          child: const SizedBox.shrink(),
        ),
    ];
    final controller = MapController();
    // Zoom 16: viewport much smaller than the 1° spread, so per-frame cost is
    // dominated by the per-marker projection + cull check.
    await tester.pumpWidget(
      _app(controller, 16, [MarkerLayer(markers: markers)]),
    );
    final us = await _benchPans(tester, controller, 16);
    debugPrint('RESULT markers_pan_mostly_culled: '
        '${us.toStringAsFixed(0)} us/frame');
  });

  test('benchmark: marker projection kernel', () {
    final rng = math.Random(5);
    final camera = MapCamera(
      crs: const Epsg3857(),
      center: _center,
      zoom: 14,
      rotation: 0,
      nonRotatedSize: const Size(800, 600),
    );
    const crs = Epsg3857();
    final points = [
      for (var i = 0; i < 10000; i++) _randomNear(rng, _center, 1),
    ];
    final projected = [for (final p in points) crs.projection.project(p)];
    const frames = 100;

    // Old per-frame path: full LatLng -> screen projection (trigonometry).
    var sink = 0.0;
    var sw = Stopwatch()..start();
    for (var f = 0; f < frames; f++) {
      for (final p in points) {
        sink += camera.projectAtZoom(p).dx;
      }
    }
    sw.stop();
    final oldNs = sw.elapsedMicroseconds * 1000 / (frames * points.length);

    // New per-frame path: linear transform of the cached projection.
    final zoomScale = crs.scale(camera.zoom);
    sw = Stopwatch()..start();
    for (var f = 0; f < frames; f++) {
      for (final p in projected) {
        final (x, _) = crs.transform(p.dx, p.dy, zoomScale);
        sink += x;
      }
    }
    sw.stop();
    final newNs = sw.elapsedMicroseconds * 1000 / (frames * points.length);

    debugPrint('RESULT marker_projection_kernel: sink=${sink.isFinite} '
        'full=${oldNs.toStringAsFixed(1)} ns/marker '
        'cached=${newNs.toStringAsFixed(1)} ns/marker');
  });

  test('benchmark: getOffsetsXY holed polygon (direct)', () {
    final rng = math.Random(11);
    final camera = MapCamera(
      crs: const Epsg3857(),
      center: _center,
      zoom: 14,
      rotation: 0,
      nonRotatedSize: const Size(800, 600),
    );
    const projection = SphericalMercator();
    final points = projection.projectList(_randomWalk(rng, _center, 500));
    final holePoints = [
      for (var h = 0; h < 10; h++)
        projection.projectList(
          _randomWalk(rng, _randomNear(rng, _center, 0.005), 200, 0.0001),
        ),
    ];

    final helper = OffsetHelper(camera: camera);
    // Warm-up.
    for (var i = 0; i < 20; i++) {
      helper.getOffsetsXY(points: points, holePoints: holePoints);
    }
    var best = double.infinity;
    for (var rep = 0; rep < 5; rep++) {
      const n = 200;
      final sw = Stopwatch()..start();
      for (var i = 0; i < n; i++) {
        helper.getOffsetsXY(points: points, holePoints: holePoints);
      }
      sw.stop();
      final per = sw.elapsedMicroseconds / n;
      if (per < best) best = per;
    }
    debugPrint('RESULT get_offsets_xy_holed: '
        '${best.toStringAsFixed(1)} us/call');
  });
}
