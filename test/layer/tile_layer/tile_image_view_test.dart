import 'dart:collection';
import 'dart:math';

import 'package:flutter/src/scheduler/ticker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image_view.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';
import 'package:test/test.dart';

import '../../test_utils/test_tile_image.dart';

void main() {
  Map<String, TileImage> tileImagesMappingFrom(List<TileImage> tileImages) =>
      // Unmodifiable ensures we don't modify the tileImage collection in
      // TileImageView
      UnmodifiableMapView({
        for (final tileImage in tileImages) tileImage.coordinates.key: tileImage
      });

  Matcher containsTileImage(
    Map<String, TileImage> tileImages,
    TileCoordinates coordinates,
  ) =>
      contains(tileImages[coordinates.key]!);

  Matcher doesNotContainTileImage(
    Map<String, TileImage> tileImages,
    TileCoordinates coordinates,
  ) =>
      isNot(containsTileImage(tileImages, coordinates));

  group('staleTiles', () {
    test('prunes tiles outside of the visible range', () {
      final tileImages = tileImagesMappingFrom([
        MockTileImage(
          coordinates: const TileCoordinates(1, 1, 1),
          loadFinished: true,
          readyToDisplay: true,
        ),
        MockTileImage(
          coordinates: const TileCoordinates(2, 1, 1),
          loadFinished: true,
          readyToDisplay: true,
        ),
      ]);

      final removalState = TileImageView(
        tileImages: tileImages,
        visibleRange: DiscreteTileRange(
          1,
          Bounds(const Point(2, 1), const Point(3, 3)),
        ),
        keepRange: DiscreteTileRange(
          1,
          Bounds(const Point(2, 1), const Point(3, 3)),
        ),
      );
      expect(
        removalState.staleTiles(),
        containsTileImage(tileImages, const TileCoordinates(1, 1, 1)),
      );
    });

    test('keeps ancestor tile if a tile has not loaded yet', () {
      final tileImages = tileImagesMappingFrom([
        MockTileImage(
          coordinates: const TileCoordinates(0, 0, 0),
          loadFinished: true,
          readyToDisplay: true,
        ),
        MockTileImage(
          coordinates: const TileCoordinates(0, 0, 1),
          loadFinished: false,
          readyToDisplay: false,
        ),
      ]);
      final removalState = TileImageView(
        tileImages: tileImages,
        visibleRange: DiscreteTileRange(
          1,
          Bounds(const Point(0, 0), const Point(0, 0)),
        ),
        keepRange: DiscreteTileRange(
          1,
          Bounds(const Point(0, 0), const Point(0, 0)),
        ),
      );
      expect(
        removalState.staleTiles(),
        doesNotContainTileImage(tileImages, const TileCoordinates(0, 0, 0)),
      );
    });

    test('keeps descendant tile if there is no loaded tile obscuring it', () {
      final tileImages = tileImagesMappingFrom([
        MockTileImage(
          coordinates: const TileCoordinates(0, 0, 0),
          loadFinished: false,
          readyToDisplay: false,
        ),
        MockTileImage(
          coordinates: const TileCoordinates(0, 0, 1),
          loadFinished: false,
          readyToDisplay: false,
        ),
        MockTileImage(
          coordinates: const TileCoordinates(0, 0, 2),
          loadFinished: true,
          readyToDisplay: true,
        ),
      ]);
      final removalState = TileImageView(
        tileImages: tileImages,
        visibleRange: DiscreteTileRange(
          1,
          Bounds(const Point(0, 0), const Point(0, 0)),
        ),
        keepRange: DiscreteTileRange(
          1,
          Bounds(const Point(0, 0), const Point(0, 0)),
        ),
      );
      expect(
        removalState.staleTiles(),
        doesNotContainTileImage(tileImages, const TileCoordinates(0, 0, 2)),
      );
    });
  });
}

class MockTileImage extends TileImage {
  @override
  final bool readyToDisplay;

  MockTileImage({
    required super.coordinates,
    required this.readyToDisplay,
    required bool loadFinished,
    void Function(TileCoordinates coordinates)? onLoadComplete,
    void Function(TileImage tile, Object error, StackTrace? stackTrace)?
        onLoadError,
    TileDisplay? tileDisplay,
    super.errorImage,
  }) : super(
          vsync: const MockTickerProvider(),
          imageProvider: testWhiteTileImage,
          onLoadComplete: onLoadComplete ?? (_) {},
          onLoadError: onLoadError ?? (_, __, ___) {},
          tileDisplay: const TileDisplay.instantaneous(),
        ) {
    loadFinishedAt = loadFinished ? DateTime.now() : null;
  }
}

class MockTickerProvider extends TickerProvider {
  const MockTickerProvider();

  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker((elapsed) {});
  }
}
