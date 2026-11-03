import 'dart:ui';

import 'package:flutter_map/src/misc/simplify.dart';
import 'package:flutter_map/src/misc/simplify_colored.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final straight = [for (var i = 0; i < 101; i++) Offset(i.toDouble(), 0)];
  test('smooth gradient retains endpoints and original indices', () {
    expect(
      simplifyColoredPoints(
        points: straight,
        colors: [
          for (var i = 0; i < 101; i++)
            Color.lerp(
                const Color(0xffff0000), const Color(0xff0000ff), i / 100)!,
        ],
        tolerance: 1,
      ),
      [0, 100],
    );
  });
  test('uniform color uses the same geometry as ordinary simplification', () {
    final points = [
      for (var i = 0; i < 100; i++) Offset(i.toDouble(), (i % 17).toDouble()),
    ];
    for (final tolerance in [0.3, 1.0, 10.0, 50.0]) {
      final indices = simplifyColoredPoints(
        points: points,
        colors: List.filled(points.length, const Color(0xff00ff00)),
        tolerance: tolerance,
      );
      expect(
        [for (final index in indices) points[index]],
        simplifyPoints(points: points, tolerance: tolerance, highQuality: true),
      );
    }
  });
  test('retains brief color and opacity peaks on straight routes', () {
    for (final peak in [const Color(0xffff0000), const Color(0x000000ff)]) {
      final colors = List.filled(straight.length, const Color(0xff0000ff));
      colors[50] = peak;
      expect(
        simplifyColoredPoints(points: straight, colors: colors, tolerance: 100),
        [0, 49, 50, 51, 100],
      );
    }
  });
  test('zero tolerance retains all samples', () {
    expect(
      simplifyColoredPoints(points: straight, colors: null, tolerance: 0),
      List.generate(straight.length, (i) => i),
    );
  });
  test('duplicate coordinates preserve meaningful color transitions', () {
    final points = List.filled(6, Offset.zero);
    final indices = simplifyColoredPoints(
      points: points,
      colors: const [
        Color(0xff0000ff),
        Color(0xff0000ff),
        Color(0xffff0000),
        Color(0xff0000ff),
        Color(0xff0000ff),
        Color(0xff0000ff),
      ],
      tolerance: 1,
    );
    expect(indices, contains(2));
    expect(indices.first, 0);
    expect(indices.last, 5);
  });
}
