import 'dart:math' as math;

import 'package:flutter_map/src/misc/point_in_polygon.dart';
import 'package:flutter_test/flutter_test.dart';

List<Offset> makeCircle(int points, double radius, double phase) {
  return List.generate(points, (i) {
    final angle = math.pi * 2 / points * i + phase;
    return Offset(radius * math.cos(angle), radius * math.sin(angle));
  }, growable: false);
}

void main() {
  test('Smoke test for points in and out of polygons', () {
    final circle = makeCircle(100, 1, 0);

    // Inside points
    for (final point in makeCircle(32, 0.8, 0.0001)) {
      final p = math.Point(point.dx, point.dy);
      expect(pointInPolygon(p, circle), isTrue);
    }

    // Edge-case: check origin
    expect(pointInPolygon(const math.Point(0, 0), circle), isTrue);

    // Outside points: small radius
    for (final point in makeCircle(32, 1.1, 0.0001)) {
      final p = math.Point(point.dx, point.dy);
      expect(pointInPolygon(p, circle), isFalse);
    }

    // Outside points: large radius
    for (final point in makeCircle(32, 100000, 0.0001)) {
      final p = math.Point(point.dx, point.dy);
      expect(pointInPolygon(p, circle), isFalse);
    }
  });
}
