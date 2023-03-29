import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds/tile_bounds_at_zoom.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinate.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

void main() {
  group('TileBoundsAtZoom', () {
    const hugeCoordinate = TileCoordinate(999999999, 999999999, 0);
    final tileRangeWithHugeCoordinate = DiscreteTileRange.fromPixelBounds(
      zoom: 0,
      tileSize: 1,
      pixelBounds: Bounds(hugeCoordinate, hugeCoordinate),
    );

    DiscreteTileRange discreteTileRange(
            int zoom, int minX, int minY, int maxX, int maxY) =>
        DiscreteTileRange(
          zoom,
          Bounds(CustomPoint(minX, minY), CustomPoint(maxX, maxY)),
        );

    test('InfiniteTileBoundsAtZoom', () {
      const tileBoundsAtZoom = InfiniteTileBoundsAtZoom();

      // Does not wrap
      expect(tileBoundsAtZoom.wrap(hugeCoordinate), hugeCoordinate);

      // Does not filter out coordinates
      expect(
        tileBoundsAtZoom.validCoordinatesIn(tileRangeWithHugeCoordinate),
        [hugeCoordinate],
      );
    });

    test('DiscreteTileBoundsAtZoom', () {
      final tileRange = discreteTileRange(0, 0, 0, 10, 10);
      final tileBoundsAtZoom = DiscreteTileBoundsAtZoom(tileRange);

      // Does not wrap
      expect(tileBoundsAtZoom.wrap(hugeCoordinate), hugeCoordinate);

      // Filters out invalid coordinates
      expect(
        tileBoundsAtZoom.validCoordinatesIn(
          discreteTileRange(0, 11, 11, 12, 12),
        ),
        isEmpty,
      );
      expect(
        tileBoundsAtZoom.validCoordinatesIn(
          discreteTileRange(0, -10, -10, -1, -1),
        ),
        isEmpty,
      );

      // Does not filter out valid coordinates
      final resultingCoordinates =
          tileBoundsAtZoom.validCoordinatesIn(tileRange);
      expect(resultingCoordinates, tileRange.coordinates);
    });

    test('WrappedTileBoundsAtZoom, wrappedTilesAlwaysValid = false', () {
      final tileRange = discreteTileRange(0, 2, 2, 10, 10);
      final tileBoundsAtZoom = WrappedTileBoundsAtZoom(
        tileRange: tileRange,
        wrappedAxisIsAlwaysInBounds: false,
        wrapX: const Tuple2(0, 12),
        wrapY: null,
      );

      // Only wraps x, x is larger than range
      expect(
        tileBoundsAtZoom.wrap(const TileCoordinate(13, 13, 0)),
        const TileCoordinate(0, 13, 0),
      );
      // Only wraps x, x is smaller than range
      expect(
        tileBoundsAtZoom.wrap(const TileCoordinate(-1, -1, 0)),
        const TileCoordinate(12, -1, 0),
      );
      // No wrap, x is within range
      expect(
        tileBoundsAtZoom.wrap(const TileCoordinate(12, 12, 0)),
        const TileCoordinate(12, 12, 0),
      );

      // Filters out invalid coordinates
      expect(
        tileBoundsAtZoom.validCoordinatesIn(
          discreteTileRange(0, 11, 11, 12, 12),
        ),
        isEmpty,
      );
      expect(
        tileBoundsAtZoom.validCoordinatesIn(
          discreteTileRange(0, -10, -10, 1, 1),
        ),
        isEmpty,
      );

      // Keeps coordinates which are in the tile range.
      expect(
        tileBoundsAtZoom.validCoordinatesIn(discreteTileRange(0, 0, 0, 12, 12)),
        discreteTileRange(0, 2, 2, 10, 10).coordinates,
      );

      // Keeps coordinates which are in the tile range when wrapped.
      expect(
        tileBoundsAtZoom
            .validCoordinatesIn(discreteTileRange(0, 13, 0, 25, 12)),
        discreteTileRange(0, 15, 2, 23, 10).coordinates,
      );
    });

    test('WrappedTileBoundsAtZoom, wrappedTilesAlwaysValid = true', () {
      final tileRange = discreteTileRange(0, 2, 2, 10, 10);
      final tileBoundsAtZoom = WrappedTileBoundsAtZoom(
        tileRange: tileRange,
        wrappedAxisIsAlwaysInBounds: true,
        wrapX: const Tuple2(0, 12),
        wrapY: null,
      );

      // Only wraps x, x is larger than range
      expect(
        tileBoundsAtZoom.wrap(const TileCoordinate(13, 13, 0)),
        const TileCoordinate(0, 13, 0),
      );
      // Only wraps x, x is smaller than range
      expect(
        tileBoundsAtZoom.wrap(const TileCoordinate(-1, -1, 0)),
        const TileCoordinate(12, -1, 0),
      );
      // No wrap, x is within range
      expect(
        tileBoundsAtZoom.wrap(const TileCoordinate(12, 12, 0)),
        const TileCoordinate(12, 12, 0),
      );

      // Filters out invalid coordinates
      expect(
        tileBoundsAtZoom.validCoordinatesIn(
          discreteTileRange(0, 11, 11, 12, 12),
        ),
        isEmpty,
      );
      expect(
        tileBoundsAtZoom.validCoordinatesIn(
          discreteTileRange(0, -10, -10, 1, 1),
        ),
        isEmpty,
      );

      // Keeps all wrapped coordinates, only non-wrapped coordinates in range.
      expect(
        tileBoundsAtZoom.validCoordinatesIn(discreteTileRange(0, 0, 0, 12, 12)),
        discreteTileRange(0, 0, 2, 12, 10).coordinates,
      );

      // Keeps all wrapped coordiantes, only non-wraped coordaintes in range.
      expect(
        tileBoundsAtZoom
            .validCoordinatesIn(discreteTileRange(0, 13, 0, 25, 12)),
        discreteTileRange(0, 13, 2, 25, 10).coordinates,
      );
    });
  });
}
