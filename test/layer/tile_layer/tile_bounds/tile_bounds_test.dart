import 'dart:math';

import 'package:flutter_map/src/geo/crs.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds/tile_bounds.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds/tile_bounds_at_zoom.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';

import 'crs_fakes.dart';

void main() {
  group('TileBounds', () {
    test('crs is infinite, latLngBounds null', () {
      final tileBounds = TileBounds(
        crs: const FakeInfiniteCrs(),
        tileSize: 256,
      );

      expect(tileBounds, isA<InfiniteTileBounds>());
      expect(tileBounds.atZoom(5), isA<InfiniteTileBoundsAtZoom>());
    });

    test('crs is infinite, latLngBounds provided', () {
      final tileBounds = TileBounds(
        crs: const FakeInfiniteCrs(),
        tileSize: 256,
        latLngBounds: LatLngBounds.fromPoints(
          [const LatLng(-44, -55), const LatLng(44, 55)],
        ),
      );

      expect(tileBounds, isA<DiscreteTileBounds>());
      expect(
        tileBounds.atZoom(5),
        isA<DiscreteTileBoundsAtZoom>().having(
          (e) => e.tileRange,
          'tileRange',
          isA<DiscreteTileRange>()
              .having((e) => e.min, 'min', const Point(11, 11))
              .having((e) => e.max, 'max', const Point(20, 20)),
        ),
      );
    });

    test('crs is finite non-wrapping', () {
      final tileBounds = TileBounds(
        crs: const CrsSimple(),
        tileSize: 256,
      );

      expect(tileBounds, isA<DiscreteTileBounds>());
      expect(
        tileBounds.atZoom(0),
        isA<DiscreteTileBoundsAtZoom>().having(
          (e) => e.tileRange,
          'tileRange',
          isA<DiscreteTileRange>()
              .having((e) => e.min, 'min', const Point<int>(-180, -90))
              .having((e) => e.max, 'max', const Point<int>(179, 89)),
        ),
      );
    });

    test('crs is finite wrapping', () {
      final tileBounds = TileBounds(
        crs: const Epsg3857(),
        tileSize: 256,
      );

      expect(tileBounds, isA<WrappedTileBounds>());
      expect(
        tileBounds.atZoom(5),
        isA<WrappedTileBoundsAtZoom>()
            .having(
              (e) => e.tileRange,
              'tileRange',
              isA<DiscreteTileRange>()
                  .having((e) => e.min, 'min', const Point<int>(0, 0))
                  .having((e) => e.max, 'max', const Point<int>(31, 31)),
            )
            .having((e) => e.wrappedAxisIsAlwaysInBounds,
                'wrappedAxisIsAlwaysInBounds', isTrue)
            .having((e) => e.wrapX, 'wrapX', const (0, 31)).having(
                (e) => e.wrapY, 'wrapY', isNull),
      );
    });

    test('crs is finite wrapping, latLngBounds provided', () {
      const crs = Epsg3857();
      final tileBounds = TileBounds(
        crs: crs,
        tileSize: 256,
        latLngBounds: LatLngBounds(
          const LatLng(0, 0),
          crs.pointToLatLng(crs.getProjectedBounds(0)!.max, 0),
        ),
      );

      expect(tileBounds, isA<WrappedTileBounds>());
      expect(
        tileBounds.atZoom(5),
        isA<WrappedTileBoundsAtZoom>()
            .having(
              (e) => e.tileRange,
              'tileRange',
              isA<DiscreteTileRange>()
                  .having((e) => e.min, 'min', const Point<int>(16, 16))
                  .having((e) => e.max, 'max', const Point<int>(31, 31)),
            )
            .having((e) => e.wrappedAxisIsAlwaysInBounds,
                'wrappedAxisIsAlwaysInBounds', isFalse)
            .having((e) => e.wrapX, 'wrapX', const (0, 31)).having(
                (e) => e.wrapY, 'wrapY', isNull),
      );
    });

    test('Has correct tile counts for Epsg3857 crs', () {
      // Taken from:
      // https://wiki.openstreetmap.org/wiki/Zoom_levels
      final expectedTileCounts = {
        0: 1,
        1: 4,
        2: 16,
        3: 64,
        4: 256,
        5: 1024,
        6: 4096,
        7: 16384,
        8: 65536,
        9: 262144,
        10: 1048576,
        11: 4194304,
        12: 16777216,
        13: 67108864,
        14: 268435456,
        15: 1073741824,
        16: 4294967296,
        17: 17179869184,
        18: 68719476736,
        19: 274877906944,
        20: 1099511627776
      };

      final tileBounds = TileBounds(
        crs: const Epsg3857(),
        tileSize: 256,
      );

      for (final entry in expectedTileCounts.entries) {
        final zoom = entry.key;
        final tileBoundsAtZoom =
            tileBounds.atZoom(zoom) as WrappedTileBoundsAtZoom;
        final minCoord = tileBoundsAtZoom.tileRange.min;
        final maxCoord = tileBoundsAtZoom.tileRange.max;

        final tileCount =
            (maxCoord.x - minCoord.x + 1) * (maxCoord.y - minCoord.y + 1);

        expect(tileCount, entry.value);
      }
    });

    test('Has correct tile ranges for Epsg3857 crs', () {
      // Inferred from (ranges are inclusive starting at 0):
      // https://wiki.openstreetmap.org/wiki/Zoom_levels
      final expectedTileRanges = {
        0: const (0, 0, 0, 0),
        1: const (0, 0, 1, 1),
        2: const (0, 0, 3, 3),
        3: const (0, 0, 7, 7),
        4: const (0, 0, 15, 15),
        5: const (0, 0, 31, 31),
        6: const (0, 0, 63, 63),
      };

      final tileBounds = TileBounds(
        crs: const Epsg3857(),
        tileSize: 256,
      );

      for (final entry in expectedTileRanges.entries) {
        final zoom = entry.key;
        final tileBoundsAtZoom =
            tileBounds.atZoom(zoom) as WrappedTileBoundsAtZoom;

        final coords = tileBoundsAtZoom.tileRange.coordinates;
        final firstCoord = coords.first;
        final lastCoord = coords.last;

        expect(
          (firstCoord.x, firstCoord.y, lastCoord.x, lastCoord.y),
          entry.value,
        );
      }
    });

    test('Has correct tile waps for Epsg3857 crs', () {
      // Inferred from (ranges are inclusive starting at 0):
      // https://wiki.openstreetmap.org/wiki/Zoom_levels
      final expectedTileRanges = {
        0: const (0, 0),
        1: const (0, 1),
        2: const (0, 3),
        3: const (0, 7),
        4: const (0, 15),
        5: const (0, 31),
        6: const (0, 63),
      };

      final tileBounds = TileBounds(
        crs: const Epsg3857(),
        tileSize: 256,
      );

      for (final entry in expectedTileRanges.entries) {
        final zoom = entry.key;
        final tileBoundsAtZoom =
            tileBounds.atZoom(zoom) as WrappedTileBoundsAtZoom;

        expect(
          tileBoundsAtZoom.wrapX,
          entry.value,
        );
      }
    });
  });
}
