import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:test/test.dart';

void main() {
  group('TileRange', () {
    group('EmptyTileRange', () {
      test('behaves as an empty range', () {
        final tileRange1 = DiscreteTileRange.fromPixelBounds(
          zoom: 0,
          tileSize: 1,
          pixelBounds: Bounds(const CustomPoint(1, 1), const CustomPoint(2, 2)),
        );
        final tileRange2 = DiscreteTileRange.fromPixelBounds(
          zoom: 0,
          tileSize: 1,
          pixelBounds: Bounds(const CustomPoint(3, 3), const CustomPoint(4, 4)),
        );
        final emptyTileRange = tileRange1.intersect(tileRange2);

        expect(
          emptyTileRange,
          isA<EmptyTileRange>()
              .having((e) => e.coordinates, 'coordinates', isEmpty),
        );
      });
    });

    group('DiscreteTileRange', () {
      group('fromPixelBounds', () {
        test('single tile', () {
          final tileRange = DiscreteTileRange.fromPixelBounds(
            zoom: 0,
            tileSize: 10,
            pixelBounds: Bounds(
              const CustomPoint(25.0, 25.0),
              const CustomPoint(25.0, 25.0),
            ),
          );

          expect(
              tileRange.coordinates.toList(), [const TileCoordinates(2, 2, 0)]);
        });

        test('lower tile edge', () {
          final tileRange = DiscreteTileRange.fromPixelBounds(
            zoom: 0,
            tileSize: 10,
            pixelBounds: Bounds(
              const CustomPoint(0.0, 0.0),
              const CustomPoint(0.1, 0.1),
            ),
          );

          expect(
              tileRange.coordinates.toList(), [const TileCoordinates(0, 0, 0)]);
        });

        test('upper tile edge', () {
          final tileRange = DiscreteTileRange.fromPixelBounds(
            zoom: 0,
            tileSize: 10,
            pixelBounds: Bounds(
              const CustomPoint(0.0, 0.0),
              const CustomPoint(9.99, 9.99),
            ),
          );

          expect(
              tileRange.coordinates.toList(), [const TileCoordinates(0, 0, 0)]);
        });

        test('both tile edges', () {
          final tileRange = DiscreteTileRange.fromPixelBounds(
            zoom: 0,
            tileSize: 10,
            pixelBounds: Bounds(
              const CustomPoint(19.99, 19.99),
              const CustomPoint(30.1, 30.1),
            ),
          );

          expect(tileRange.coordinates.toList(), [
            const TileCoordinates(1, 1, 0),
            const TileCoordinates(2, 1, 0),
            const TileCoordinates(3, 1, 0),
            const TileCoordinates(1, 2, 0),
            const TileCoordinates(2, 2, 0),
            const TileCoordinates(3, 2, 0),
            const TileCoordinates(1, 3, 0),
            const TileCoordinates(2, 3, 0),
            const TileCoordinates(3, 3, 0),
          ]);
        });
      });

      test('expand', () {
        final tileRange = DiscreteTileRange.fromPixelBounds(
          zoom: 0,
          tileSize: 10,
          pixelBounds: Bounds(
            const CustomPoint(25.0, 25.0),
            const CustomPoint(25.0, 25.0),
          ),
        );

        expect(
            tileRange.coordinates.toList(), [const TileCoordinates(2, 2, 0)]);
        final expandedTileRange = tileRange.expand(1);

        expect(expandedTileRange.coordinates.toList(), [
          const TileCoordinates(1, 1, 0),
          const TileCoordinates(2, 1, 0),
          const TileCoordinates(3, 1, 0),
          const TileCoordinates(1, 2, 0),
          const TileCoordinates(2, 2, 0),
          const TileCoordinates(3, 2, 0),
          const TileCoordinates(1, 3, 0),
          const TileCoordinates(2, 3, 0),
          const TileCoordinates(3, 3, 0),
        ]);
      });

      test('no intersection', () {
        final tileRange1 = DiscreteTileRange.fromPixelBounds(
          zoom: 0,
          tileSize: 10,
          pixelBounds: Bounds(
            const CustomPoint(25.0, 25.0),
            const CustomPoint(25.0, 25.0),
          ),
        );

        final tileRange2 = DiscreteTileRange.fromPixelBounds(
          zoom: 0,
          tileSize: 10,
          pixelBounds: Bounds(
            const CustomPoint(35.0, 35.0),
            const CustomPoint(35.0, 35.0),
          ),
        );

        final intersectionA = tileRange1.intersect(tileRange2);
        final intersectionB = tileRange1.intersect(tileRange2);

        expect(intersectionA, isA<EmptyTileRange>());
        expect(intersectionB, isA<EmptyTileRange>());
      });

      test('intersects', () {
        final tileRange1 = DiscreteTileRange.fromPixelBounds(
          zoom: 0,
          tileSize: 10,
          pixelBounds: Bounds(
            const CustomPoint(25.0, 25.0),
            const CustomPoint(35.0, 35.0),
          ),
        );

        final tileRange2 = DiscreteTileRange.fromPixelBounds(
          zoom: 0,
          tileSize: 10,
          pixelBounds: Bounds(
            const CustomPoint(35.0, 35.0),
            const CustomPoint(45.0, 45.0),
          ),
        );

        final intersectionA =
            tileRange1.intersect(tileRange2).coordinates.toList();
        final intersectionB =
            tileRange1.intersect(tileRange2).coordinates.toList();

        expect(intersectionA, [const TileCoordinates(3, 3, 0)]);
        expect(intersectionB, [const TileCoordinates(3, 3, 0)]);
      });

      test('range within other range', () {
        final tileRange1 = DiscreteTileRange.fromPixelBounds(
          zoom: 0,
          tileSize: 10,
          pixelBounds: Bounds(
            const CustomPoint(25.0, 25.0),
            const CustomPoint(35.0, 35.0),
          ),
        );

        final tileRange2 = DiscreteTileRange.fromPixelBounds(
          zoom: 0,
          tileSize: 10,
          pixelBounds: Bounds(
            const CustomPoint(15.0, 15.0),
            const CustomPoint(45.0, 45.0),
          ),
        );

        final intersectionA =
            tileRange1.intersect(tileRange2).coordinates.toList();
        final intersectionB =
            tileRange1.intersect(tileRange2).coordinates.toList();

        expect(intersectionA, tileRange1.coordinates.toList());
        expect(intersectionB, tileRange1.coordinates.toList());
      });
    });

    test('min/max', () {
      final tileRange = DiscreteTileRange.fromPixelBounds(
        zoom: 0,
        tileSize: 10,
        pixelBounds: Bounds(
          const CustomPoint(35.0, 35.0),
          const CustomPoint(45.0, 45.0),
        ),
      );

      expect(tileRange.min, (const CustomPoint(3, 3)));
      expect(tileRange.max, (const CustomPoint(4, 4)));
    });

    group('center', () {
      test('one tile', () {
        final tileRange = DiscreteTileRange.fromPixelBounds(
          zoom: 0,
          tileSize: 10,
          pixelBounds: Bounds(
            const CustomPoint(35.0, 35.0),
            const CustomPoint(35.0, 35.0),
          ),
        );

        expect(tileRange.center, const CustomPoint(3, 3));
      });

      test('multiple tiles, even number of tiles', () {
        final tileRange = DiscreteTileRange.fromPixelBounds(
          zoom: 0,
          tileSize: 10,
          pixelBounds: Bounds(
            const CustomPoint(35.0, 35.0),
            const CustomPoint(45.0, 45.0),
          ),
        );

        expect(tileRange.center, const CustomPoint(3.5, 3.5));
      });

      test('multiple tiles, odd number of tiles', () {
        final tileRange = DiscreteTileRange.fromPixelBounds(
          zoom: 0,
          tileSize: 10,
          pixelBounds: Bounds(
            const CustomPoint(35.0, 35.0),
            const CustomPoint(55.0, 55.0),
          ),
        );

        expect(tileRange.center, const CustomPoint(4, 4));
      });
    });

    test('contains', () {
      final tileRange = DiscreteTileRange.fromPixelBounds(
        zoom: 0,
        tileSize: 10,
        pixelBounds: Bounds(
          const CustomPoint(35.0, 35.0),
          const CustomPoint(35.0, 35.0),
        ),
      );

      expect(tileRange.contains(const CustomPoint(2, 2)), isFalse);
      expect(tileRange.contains(const CustomPoint(3, 2)), isFalse);
      expect(tileRange.contains(const CustomPoint(4, 2)), isFalse);
      expect(tileRange.contains(const CustomPoint(2, 3)), isFalse);
      expect(tileRange.contains(const CustomPoint(3, 3)), isTrue);
      expect(tileRange.contains(const CustomPoint(4, 3)), isFalse);
      expect(tileRange.contains(const CustomPoint(2, 4)), isFalse);
      expect(tileRange.contains(const CustomPoint(3, 4)), isFalse);
      expect(tileRange.contains(const CustomPoint(4, 4)), isFalse);
    });
  });
}
