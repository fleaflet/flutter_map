import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_map/src/misc/simplify.dart';

/// Source indices retained by geometry- and color-aware Douglas-Peucker.
///
/// Colors are compared with the gradient at the projected position on each
/// candidate segment. The maximum permitted error is 0.02 per RGBA channel.
/// Indices preserve metadata through simplification, including repeated points.
List<int> simplifyColoredPoints({
  required List<Offset> points,
  required List<Color>? colors,
  required double tolerance,
}) {
  assert(colors == null || colors.length == points.length,
      'Colors must correspond to every source point');
  if (points.length <= 4 || tolerance <= 0) {
    return List.generate(points.length, (index) => index);
  }
  final keep = List<bool>.filled(points.length, false);
  keep.first = keep.last = true;
  final pending = <(int, int)>[(0, points.length - 1)];
  final squaredTolerance = tolerance * tolerance;
  while (pending.isNotEmpty) {
    final (first, last) = pending.removeLast();
    final start = points[first];
    final end = points[last];
    final delta = end - start;
    final lengthSquared = delta.distanceSquared;
    var greatestError = 1.0;
    var selected = -1;
    for (var index = first + 1; index < last; index++) {
      final point = points[index];
      var error =
          getSqSegDist(point.dx, point.dy, start.dx, start.dy, end.dx, end.dy) /
              squaredTolerance;
      if (colors != null) {
        final fraction = lengthSquared == 0
            ? (index - first) / (last - first)
            : (((point.dx - start.dx) * delta.dx +
                        (point.dy - start.dy) * delta.dy) /
                    lengthSquared)
                .clamp(0.0, 1.0);
        final expected = Color.lerp(colors[first], colors[last], fraction)!;
        final actual = colors[index];
        final colorError = [
          (actual.r - expected.r).abs(),
          (actual.g - expected.g).abs(),
          (actual.b - expected.b).abs(),
          (actual.a - expected.a).abs(),
        ].reduce(math.max);
        error = math.max(error, colorError / 0.02);
      }
      if (error > greatestError) {
        greatestError = error;
        selected = index;
      }
    }
    if (selected != -1) {
      keep[selected] = true;
      if (selected - first > 1) pending.add((first, selected));
      if (last - selected > 1) pending.add((selected, last));
    }
  }
  return [
    for (var i = 0; i < keep.length; i++)
      if (keep[i]) i
  ];
}
