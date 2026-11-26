import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

// CPU build/paint timings in the widget-test runner, not GPU frame timings.
// Run the identical file before/after with --concurrency=1 on the same machine.
void main() {
  for (final count in [5000, 20000]) {
    for (final mode in ['plain', 'solid-multicolor', 'gradient', 'outlined']) {
      for (final zooming in [false, true]) {
        testWidgets('$mode $count ${zooming ? 'zoom' : 'pan'} benchmark',
            (tester) async {
          final points = [
            for (var i = 0; i < count; i++)
              LatLng(43 + 0.008 * math.sin(i / count * math.pi * 8),
                  -79 + 0.012 * math.cos(i / count * math.pi * 6)),
          ];
          final colors = [
            for (var i = 0; i < count; i++)
              Color.lerp(Colors.blue, Colors.red, (i % 100) / 99)!,
          ];
          final lines = <Polyline>[
            if (mode == 'plain')
              Polyline(points: points, color: Colors.white, strokeWidth: 7),
            if (mode == 'solid-multicolor' || mode == 'outlined')
              MulticolorPolyline(
                  points: points,
                  defaultColor: Colors.white,
                  simplificationColors: mode == 'outlined' ? colors : null,
                  strokeWidth: 7),
            if (mode == 'gradient' || mode == 'outlined')
              MulticolorPolyline(
                  points: points, vertexColors: colors, strokeWidth: 4.5),
          ];
          final controller = MapController();
          await tester.pumpWidget(MaterialApp(
              home: FlutterMap(
            mapController: controller,
            options: const MapOptions(
                initialCenter: LatLng(43, -79), initialZoom: 14),
            children: [PolylineLayer(polylines: lines)],
          )));
          Future<void> frame(int i) async {
            controller.move(
                LatLng(43 + (i % 7) * 0.00003, -79 + (i % 11) * 0.00003),
                zooming ? 13.5 + (i % 20) * 0.05 : 14);
            await tester.pump();
          }

          for (var i = 0; i < 15; i++) {
            await frame(i);
          }
          final samples = <double>[];
          for (var repeat = 0; repeat < 5; repeat++) {
            final timer = Stopwatch()..start();
            for (var i = 0; i < 30; i++) {
              await frame(i);
            }
            samples.add(timer.elapsedMicroseconds / 30);
          }
          samples.sort();
          debugPrint('RESULT $mode points=$count ${zooming ? 'zoom' : 'pan'} '
              'median_us=${samples[2].round()} min_us=${samples.first.round()}');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          controller.dispose();
        });
      }
    }
  }
}
