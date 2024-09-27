import 'dart:async';
import 'dart:math';

import 'package:flutter/src/scheduler/ticker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image_view.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:test/test.dart';

import '../../test_utils/test_tile_image.dart';

void main() {
  Map<TileCoordinates, TileImage> tileImagesMappingFrom(
          List<TileImage> tileImages) =>
      {for (final tileImage in tileImages) tileImage.coordinates: tileImage};

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
      const zoom = 10;
      final tileImages = tileImagesMappingFrom([
        MockTileImage(1, 1, zoom),
        MockTileImage(2, 1, zoom),
      ]);

      final removalState = TileImageView(
        tileImages: tileImages,
        positionCoordinates: Set<TileCoordinates>.from(tileImages.keys),
        visibleRange: discreteTileRange(2, 1, 3, 3, zoom: zoom),
        keepRange: discreteTileRange(2, 1, 3, 3, zoom: zoom),
      );
      expect(
        removalState.staleTiles,
        contains(const TileCoordinates(1, 1, zoom)),
      );
    });

    test('ancestor tile is not stale if a tile has not loaded yet', () {
      final tileImages = tileImagesMappingFrom([
        MockTileImage(0, 0, 0),
        MockTileImage(0, 0, 1, loadFinished: false, readyToDisplay: false),
      ]);
      final removalState = TileImageView(
        tileImages: tileImages,
        positionCoordinates: Set<TileCoordinates>.from(tileImages.keys),
        visibleRange: discreteTileRange(0, 0, 0, 0, zoom: 1),
        keepRange: discreteTileRange(0, 0, 0, 0, zoom: 1),
      );
      expect(
        removalState.staleTiles,
        isNot(contains(const TileCoordinates(0, 0, 0))),
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
        positionCoordinates: Set<TileCoordinates>.from(tileImages.keys),
        visibleRange: discreteTileRange(0, 0, 0, 0, zoom: 1),
        keepRange: discreteTileRange(0, 0, 0, 0, zoom: 1),
      );
      expect(
        removalState.staleTiles,
        isNot(contains(const TileCoordinates(0, 0, 2))),
      );
    });

    test(
        'returned elements can be removed from the source collection in a for loop',
        () {
      const zoom = 10;
      final tileImages = tileImagesMappingFrom([
        MockTileImage(1, 1, zoom),
      ]);

      final removalState = TileImageView(
        tileImages: tileImages,
        positionCoordinates: Set<TileCoordinates>.from(tileImages.keys),
        visibleRange: discreteTileRange(2, 1, 3, 3, zoom: zoom),
        keepRange: discreteTileRange(2, 1, 3, 3, zoom: zoom),
      );
      expect(
        removalState.staleTiles,
        contains(const TileCoordinates(1, 1, zoom)),
      );
      // If an iterator over the original collection is returned then when
      // looping over that iterator and removing from the original collection
      // a concurrent modification exception is thrown. This ensures that the
      // returned collection is not an iterable over the original collection.
      for (final staleTile in removalState.staleTiles) {
        tileImages.remove(staleTile)!;
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
      positionCoordinates: Set<TileCoordinates>.from(tileImages.keys),
      visibleRange: discreteTileRange(1, 2, 1, 2, zoom: 1),
      keepRange: discreteTileRange(1, 2, 2, 2, zoom: 1),
    );
    expect(
      tileImageView.errorTilesOutsideOfKeepMargin(),
      [const TileCoordinates(1, 1, 1)],
    );

    // If an iterator over the original collection is returned then when
    // looping over that iterator and removing from the original collection
    // a concurrent modification exception is thrown. This ensures that the
    // returned collection is not an iterable over the original collection.
    for (final coordinates in tileImageView.errorTilesOutsideOfKeepMargin()) {
      tileImages.remove(coordinates)!;
    }
  });

  test('errorTilesNotVisible', () {
    const zoom = 10;
    final tileImages = tileImagesMappingFrom([
      MockTileImage(1, 1, zoom, loadError: true),
      MockTileImage(2, 1, zoom),
      MockTileImage(1, 2, zoom),
      MockTileImage(2, 2, zoom, loadError: true),
    ]);
    final tileImageView = TileImageView(
      tileImages: tileImages,
      positionCoordinates: Set<TileCoordinates>.from(tileImages.keys),
      visibleRange: discreteTileRange(1, 2, 1, 2, zoom: zoom),
      keepRange: discreteTileRange(1, 2, 2, 2, zoom: zoom),
    );
    expect(
      tileImageView.errorTilesNotVisible(),
      [const TileCoordinates(1, 1, zoom), const TileCoordinates(2, 2, zoom)],
    );

    // If an iterator over the original collection is returned then when
    // looping over that iterator and removing from the original collection
    // a concurrent modification exception is thrown. This ensures that the
    // returned collection is not an iterable over the original collection.
    for (final coordinates in tileImageView.errorTilesOutsideOfKeepMargin()) {
      tileImages.remove(coordinates)!;
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
