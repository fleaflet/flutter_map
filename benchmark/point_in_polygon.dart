// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_map/src/misc/point_in_polygon.dart';

typedef Result = ({
  String name,
  Duration duration,
});

Future<Result> timedRun(String name, dynamic Function() body) async {
  print('running $name...');
  final watch = Stopwatch()..start();
  await body();
  watch.stop();

  return (name: name, duration: watch.elapsed);
}

List<Offset> makeCircle(int points, double radius, double phase) {
  final slice = math.pi * 2 / (points - 1);
  return List.generate(points, (i) {
    // Note the modulo is only there to deal with floating point imprecision
    // and ensure first == last.
    final angle = slice * (i % (points - 1)) + phase;
    return Offset(radius * math.cos(angle), radius * math.sin(angle));
  }, growable: false);
}

// NOTE: to have a more prod like comparison, run with:
//     $ dart compile exe benchmark/crs.dart && ./benchmark/crs.exe
//
// If you run in JIT mode, the resulting execution times will be a lot more similar.
Future<void> main() async {
  final results = <Result>[];
  const N = 3000000;

  final circle = makeCircle(1000, 1, 0);

  results.add(await timedRun('In circle', () {
    const point = Offset.zero;

    bool yesPlease = true;
    for (int i = 0; i < N; ++i) {
      yesPlease = yesPlease && isPointInPolygon(point, circle);
    }

    assert(yesPlease, 'should be in circle');
    return yesPlease;
  }));

  results.add(await timedRun('Not in circle', () {
    const point = Offset(4, 4);

    bool noSir = false;
    for (int i = 0; i < N; ++i) {
      noSir = noSir || isPointInPolygon(point, circle);
    }

    assert(!noSir, 'should not be in circle');
    return noSir;
  }));

  print('Results:\n${results.map((r) => r.toString()).join('\n')}');
}
