import 'dart:math';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds/tile_bounds.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_cover.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:flutter_map/src/misc/bounds.dart';
import 'package:test/test.dart';

void main() {
  group('contains', () {
    test('compares the zoom', () {
      final cover = TileCover(const [TileCoordinates(1, 1, 5)]);
      expect(cover.contains(const TileCoordinates(1, 1, 5)), isTrue);
      expect(cover.contains(const TileCoordinates(1, 1, 4)), isFalse);
      expect(cover.contains(const TileCoordinates(1, 1, 6)), isFalse);
    });

    test('a range compares the zoom of tile coordinates', () {
      final range = DiscreteTileRange(
          5, IntegerBounds(const Point(1, 1), const Point(2, 2)));
      expect(range.contains(const TileCoordinates(1, 1, 5)), isTrue);
      expect(range.contains(const TileCoordinates(1, 1, 4)), isFalse);
      expect(range.contains(const Point(1, 1)), isTrue);
    });

    test('wraps x at the zoom of the coordinates', () {
      final cover = TileCover(const [
        TileCoordinates(1, 0, 1),
        TileCoordinates(5, 0, 3),
      ]);
      bool wrapped(TileCoordinates c) =>
          cover.contains(c, replicatesWorldLongitude: true);

      expect(wrapped(const TileCoordinates(3, 0, 1)), isTrue);
      expect(wrapped(const TileCoordinates(-1, 0, 1)), isTrue);
      expect(wrapped(const TileCoordinates(13, 0, 3)), isTrue);
      expect(wrapped(const TileCoordinates(-3, 0, 3)), isTrue);
      expect(wrapped(const TileCoordinates(2, 0, 1)), isFalse);
      expect(wrapped(const TileCoordinates(12, 0, 3)), isFalse);
      expect(wrapped(const TileCoordinates(3, 0, 2)), isFalse);
      expect(cover.contains(const TileCoordinates(3, 0, 1)), isFalse);
    });
  });

  group('expand', () {
    test('of a single zoom equals the expanded range', () {
      final range = DiscreteTileRange(
        7,
        IntegerBounds(const Point(2, 3), const Point(4, 6)),
      );
      final cover = TileCover(range.coordinates);
      for (final count in [0, 1, 2]) {
        expect(
          cover.expand(count).coordinates.toSet(),
          range.expand(count).coordinates.toSet(),
          reason: 'count $count',
        );
      }
    });

    test('adds a ring at the zoom of each tile', () {
      final cover = TileCover(const [
        TileCoordinates(4, 4, 5),
        TileCoordinates(1, 1, 3),
      ]).expand(1);
      expect(cover.coordinates.toSet(), {
        for (final (x, y, z) in [(4, 4, 5), (1, 1, 3)])
          for (var j = y - 1; j <= y + 1; j++)
            for (var i = x - 1; i <= x + 1; i++) TileCoordinates(i, j, z),
      });
    });

    test('of a rotated cover adds no corners of its bounding box', () {
      final cover = TileCover(const [
        TileCoordinates(5, 3, 4),
        TileCoordinates(4, 4, 4),
        TileCoordinates(5, 4, 4),
        TileCoordinates(6, 4, 4),
        TileCoordinates(5, 5, 4),
      ]).expand(1);
      expect(cover.contains(const TileCoordinates(3, 2, 4)), isFalse);
      expect(cover.contains(const TileCoordinates(4, 2, 4)), isTrue);
    });
  });

  test('validCoordinatesIn applies the bounds at the zoom of each tile', () {
    final bounds = TileBounds(crs: const Epsg3857(), tileDimension: 256);
    final cover = TileCover(const [
      TileCoordinates(0, 0, 1),
      TileCoordinates(5, 1, 1),
      TileCoordinates(0, 3, 1),
      TileCoordinates(0, 3, 2),
      TileCoordinates(0, -1, 2),
    ]);
    expect(cover.validCoordinatesIn(bounds).toSet(), {
      const TileCoordinates(0, 0, 1),
      const TileCoordinates(5, 1, 1),
      const TileCoordinates(0, 3, 2),
    });
  });
}
