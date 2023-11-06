import 'dart:async';
import 'dart:math';

import 'package:flutter/src/scheduler/ticker.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_display.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image_view.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:flutter_map/src/misc/bounds.dart';
import 'package:test/test.dart';

import '../../test_utils/test_tile_image.dart';

void main() {
  Map<TileCoordinates, TileImage> tileImagesMappingFrom(
          List<TileImage> tileImages) =>
      {for (final tileImage in tileImages) tileImage.coordinates: tileImage};

  Matcher containsTileImage(
    Map<TileCoordinates, TileImage> tileImages,
    TileCoordinates coordinates,
  ) =>
      contains(tileImages[coordinates]);

  Matcher doesNotContainTileImage(
    Map<TileCoordinates, TileImage> tileImages,
    TileCoordinates coordinates,
  ) =>
      isNot(containsTileImage(tileImages, coordinates));

  DiscreteTileRange discreteTileRange(
    int x1,
    int y1,
    int x2,
    int y2, {
    required int zoom,
  }) =>
      DiscreteTileRange(
        zoom,
        Bounds(Point(x1, y1), Point(x2, y2)),
      );

  group('staleTiles', () {
    test('tiles outside of the keep range are stale', () {
      final tileImages = tileImagesMappingFrom([
        MockTileImage(1, 1, 1),
        MockTileImage(2, 1, 1),
      ]);

      final removalState = TileImageView(
        tileImages: tileImages,
        visibleRange: discreteTileRange(2, 1, 3, 3, zoom: 1),
        keepRange: discreteTileRange(2, 1, 3, 3, zoom: 1),
      );
      expect(
        removalState.staleTiles,
        containsTileImage(tileImages, const TileCoordinates(1, 1, 1)),
      );
    });

    test('ancestor tile is not stale if a tile has not loaded yet', () {
      final tileImages = tileImagesMappingFrom([
        MockTileImage(0, 0, 0),
        MockTileImage(0, 0, 1, loadFinished: false, readyToDisplay: false),
      ]);
      final removalState = TileImageView(
        tileImages: tileImages,
        visibleRange: discreteTileRange(0, 0, 0, 0, zoom: 1),
        keepRange: discreteTileRange(0, 0, 0, 0, zoom: 1),
      );
      expect(
        removalState.staleTiles,
        doesNotContainTileImage(tileImages, const TileCoordinates(0, 0, 0)),
      );
    });

    test('descendant tile is not stale if there is no loaded tile obscuring it',
        () {
      final tileImages = tileImagesMappingFrom([
        MockTileImage(0, 0, 0, loadFinished: false, readyToDisplay: false),
        MockTileImage(0, 0, 1, loadFinished: false, readyToDisplay: false),
        MockTileImage(0, 0, 2),
      ]);
      final removalState = TileImageView(
        tileImages: tileImages,
        visibleRange: discreteTileRange(0, 0, 0, 0, zoom: 1),
        keepRange: discreteTileRange(0, 0, 0, 0, zoom: 1),
      );
      expect(
        removalState.staleTiles,
        doesNotContainTileImage(tileImages, const TileCoordinates(0, 0, 2)),
      );
    });

    test(
        'returned elements can be removed from the source collection in a for loop',
        () {
      final tileImages = tileImagesMappingFrom([
        MockTileImage(1, 1, 1),
      ]);

      final removalState = TileImageView(
        tileImages: tileImages,
        visibleRange: discreteTileRange(2, 1, 3, 3, zoom: 1),
        keepRange: discreteTileRange(2, 1, 3, 3, zoom: 1),
      );
      expect(
        removalState.staleTiles,
        containsTileImage(tileImages, const TileCoordinates(1, 1, 1)),
      );
      // If an iterator over the original collection is returned then when
      // looping over that iterator and removing from the original collection
      // a concurrent modification exception is thrown. This ensures that the
      // returned collection is not an iterable over the original collection.
      for (final staleTile in removalState.staleTiles) {
        tileImages.remove(staleTile.coordinates)!;
      }
    });
  });

  test('errorTilesOutsideOfKeepMargin', () {
    final tileImages = tileImagesMappingFrom([
      MockTileImage(1, 1, 1, loadError: true),
      MockTileImage(2, 1, 1),
      MockTileImage(1, 2, 1),
      MockTileImage(2, 2, 1, loadError: true),
    ]);
    final tileImageView = TileImageView(
      tileImages: tileImages,
      visibleRange: discreteTileRange(1, 2, 1, 2, zoom: 1),
      keepRange: discreteTileRange(1, 2, 2, 2, zoom: 1),
    );
    expect(
      tileImageView.errorTilesOutsideOfKeepMargin().map((e) => e.coordinates),
      [const TileCoordinates(1, 1, 1)],
    );

    // If an iterator over the original collection is returned then when
    // looping over that iterator and removing from the original collection
    // a concurrent modification exception is thrown. This ensures that the
    // returned collection is not an iterable over the original collection.
    for (final tileImage in tileImageView.errorTilesOutsideOfKeepMargin()) {
      tileImages.remove(tileImage.coordinates)!;
    }
  });

  test('errorTilesNotVisible', () {
    final tileImages = tileImagesMappingFrom([
      MockTileImage(1, 1, 1, loadError: true),
      MockTileImage(2, 1, 1),
      MockTileImage(1, 2, 1),
      MockTileImage(2, 2, 1, loadError: true),
    ]);
    final tileImageView = TileImageView(
      tileImages: tileImages,
      visibleRange: discreteTileRange(1, 2, 1, 2, zoom: 1),
      keepRange: discreteTileRange(1, 2, 2, 2, zoom: 1),
    );
    expect(
      tileImageView.errorTilesNotVisible().map((e) => e.coordinates),
      [const TileCoordinates(1, 1, 1), const TileCoordinates(2, 2, 1)],
    );

    // If an iterator over the original collection is returned then when
    // looping over that iterator and removing from the original collection
    // a concurrent modification exception is thrown. This ensures that the
    // returned collection is not an iterable over the original collection.
    for (final tileImage in tileImageView.errorTilesOutsideOfKeepMargin()) {
      tileImages.remove(tileImage.coordinates)!;
    }
  });
}

class MockTileImage extends TileImage {
  @override
  final bool readyToDisplay;

  MockTileImage(
    int x,
    int y,
    int zoom, {
    this.readyToDisplay = true,
    bool loadFinished = true,
    bool loadError = false,
    void Function(TileCoordinates coordinates)? onLoadComplete,
    void Function(TileImage tile, Object error, StackTrace? stackTrace)?
        onLoadError,
    TileDisplay? tileDisplay,
    super.errorImage,
  }) : super(
          coordinates: TileCoordinates(x, y, zoom),
          vsync: const MockTickerProvider(),
          imageProvider: testWhiteTileImage,
          onLoadComplete: onLoadComplete ?? (_) {},
          onLoadError: onLoadError ?? (_, __, ___) {},
          tileDisplay: const TileDisplay.instantaneous(),
          cancelLoading: Completer(),
        ) {
    loadFinishedAt = loadFinished ? DateTime.now() : null;
    this.loadError = loadError;
  }
}

class MockTickerProvider extends TickerProvider {
  const MockTickerProvider();

  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker((elapsed) {});
  }
}
