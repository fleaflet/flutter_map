import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_map/src/geo/crs.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

class NoFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

typedef Result = ({
  String name,
  Duration duration,
});

Future<Result> timedRun(String name, dynamic Function() body) async {
  Logger().i('running $name...');
  final watch = Stopwatch()..start();
  await body();
  watch.stop();

  return (name: name, duration: watch.elapsed);
}

// NOTE: to have a more prod like comparison, run with:
//     $ dart compile exe benchmark/crs.dart && ./benchmark/crs.exe
//
// If you run in JIT mode, the resulting execution times will be a lot more similar.
Future<void> main() async {
  Logger.level = Level.all;
  Logger.defaultFilter = NoFilter.new;
  Logger.defaultPrinter = SimplePrinter.new;

  final results = <Result>[];
  const N = 100000000;

  const crs = Epsg3857();
  results.add(await timedRun('Concrete type: ${crs.code}.latLngToXY()', () {
    double x = 0;
    double y = 0;
    for (int i = 0; i < N; ++i) {
      final latlng = LatLng((i % 90).toDouble(), (i % 180).toDouble());
      final (cx, cy) = crs.latLngToXY(latlng, 1);
      x += cx;
      y += cy;
    }
    return x + y;
  }));

  results.add(await timedRun('Concrete type: ${crs.code}.latLngToPoint()', () {
    double x = 0;
    double y = 0;
    for (int i = 0; i < N; ++i) {
      final latlng = LatLng((i % 90).toDouble(), (i % 180).toDouble());
      final p = crs.latLngToPoint(latlng, 1);
      x += p.x;
      y += p.y;
    }
    return x + y;
  }));

  const crss = <Crs>[
    Epsg3857(),
    Epsg4326(),
  ];

  for (final crs in crss) {
    results.add(await timedRun('${crs.code}.latLngToXY()', () {
      double x = 0;
      double y = 0;
      for (int i = 0; i < N; ++i) {
        final latlng = LatLng((i % 90).toDouble(), (i % 180).toDouble());
        final (cx, cy) = crs.latLngToXY(latlng, 1);
        x += cx;
        y += cy;
      }
      return x + y;
    }));

    results.add(await timedRun('${crs.code}.latlngToPoint()', () {
      double x = 0;
      double y = 0;
      for (int i = 0; i < N; ++i) {
        final latlng = LatLng((i % 90).toDouble(), (i % 180).toDouble());
        final point = crs.latLngToPoint(latlng, 1);
        x += point.x;
        y += point.y;
      }
      return x + y;
    }));

    results.add(await timedRun('${crs.code}.pointToLatLng()', () {
      double x = 0;
      double y = 0;
      for (int i = 0; i < N; ++i) {
        final latlng = crs.pointToLatLng(math.Point<double>(x, y), 1);
        x += latlng.longitude;
        y += latlng.latitude;
      }
      return x + y;
    }));
  }

  Logger().i('Results:\n${results.map((r) => r.toString()).join('\n')}');
}
