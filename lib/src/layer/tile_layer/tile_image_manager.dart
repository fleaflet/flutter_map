import 'package:collection/collection.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds/tile_bounds.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds/tile_bounds_at_zoom.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_display.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image_view.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:meta/meta.dart';

typedef TileCreator = TileImage Function(TileCoordinates coordinates);

@immutable
class TileImageManager {
  final Map<String, TileImage> _tiles = {};

  bool containsTileAt(TileCoordinates coordinates) =>
      _tiles.containsKey(coordinates.key);

  bool get allLoaded =>
      _tiles.values.none((tile) => tile.loadFinishedAt == null);

  /// Returns in the order in which they should be rendered:
  ///   1. Tiles at the current zoom.
  ///   2. Tiles at the current zoom +/- 1.
  ///   3. Tiles at the current zoom +/- 2.
  ///   4. ...etc
  List<TileImage> inRenderOrder(double maxZoom, int currentZoom) {
    final result = _tiles.values.toList()
      ..sort((a, b) => a
          .zIndex(maxZoom, currentZoom)
          .compareTo(b.zIndex(maxZoom, currentZoom)));

    return result;
  }

  // Creates missing tiles in the given range. Does not initiate loading of the
  // tiles.
  void createMissingTiles(
    DiscreteTileRange tileRange,
    TileBoundsAtZoom tileBoundsAtZoom, {
    required TileCreator createTileImage,
  }) {
    for (final coordinates in tileBoundsAtZoom.validCoordinatesIn(tileRange)) {
      _tiles.putIfAbsent(
        coordinates.key,
        () => createTileImage(coordinates),
      );
    }
  }

  bool allWithinZoom(double minZoom, double maxZoom) => _tiles.values
      .map((e) => e.coordinates)
      .every((coord) => coord.z > maxZoom || coord.z < minZoom);

  /// Creates and returns [TileImage]s which do not already exist with the given
  /// [tileCoordinates].
  List<TileImage> createMissingTilesIn(
    Iterable<TileCoordinates> tileCoordinates, {
    required TileCreator createTile,
  }) {
    final notLoaded = <TileImage>[];

    for (final coordinates in tileCoordinates) {
      final tile = _tiles.putIfAbsent(
        coordinates.key,
        () => createTile(coordinates),
      );

      if (tile.loadStarted == null) notLoaded.add(tile);
    }

    return notLoaded;
  }

  void updateTileDisplay(TileDisplay tileDisplay) {
    for (final tile in _tiles.values) {
      tile.tileDisplay = tileDisplay;
    }
  }

  /// All removals should be performed by calling this method to ensure that
  // disposal is performed correctly.
  void _remove(
    String key, {
    required bool Function(TileImage tileImage) evictImageFromCache,
  }) {
    final removed = _tiles.remove(key);

    if (removed != null) {
      removed.dispose(evictImageFromCache: evictImageFromCache(removed));
    }
  }

  void _removeWithEvictionStrategy(
    String key,
    EvictErrorTileStrategy strategy,
  ) {
    _remove(
      key,
      evictImageFromCache: (tileImage) =>
          tileImage.loadError && strategy != EvictErrorTileStrategy.none,
    );
  }

  void removeAll(EvictErrorTileStrategy evictStrategy) {
    final keysToRemove = List<String>.from(_tiles.keys);

    for (final key in keysToRemove) {
      _removeWithEvictionStrategy(key, evictStrategy);
    }
  }

  void reloadImages(
    TileLayer layer,
    TileBounds tileBounds,
  ) {
    // If a TileImage's imageInfo is already available when load() is called it
    // will call its onLoadComplete callback synchronously which can trigger
    // pruning. Since pruning may cause removals from _tiles we must not
    // iterate _tiles directly otherwise a concurrent modification error may
    // occur. To avoid this we create a copy of the collection of tiles to
    // reload and iterate over that instead.
    final tilesToReload = List<TileImage>.from(_tiles.values);

    for (final tile in tilesToReload) {
      tile.imageProvider = layer.tileProvider.getImage(
        tileBounds.atZoom(tile.coordinates.z).wrap(tile.coordinates),
        layer,
      );
      tile.load();
    }
  }

  void evictAndPrune({
    required DiscreteTileRange visibleRange,
    required int pruneBuffer,
    required EvictErrorTileStrategy evictStrategy,
  }) {
    final pruningState = TileImageView(
      tileImages: _tiles,
      visibleRange: visibleRange,
      keepRange: visibleRange.expand(pruneBuffer),
    );

    _evictErrorTiles(pruningState, evictStrategy);
    _prune(pruningState, evictStrategy);
  }

  void _evictErrorTiles(
    TileImageView tileRemovalState,
    EvictErrorTileStrategy evictStrategy,
  ) {
    switch (evictStrategy) {
      case EvictErrorTileStrategy.notVisibleRespectMargin:
        for (final tileImage
            in tileRemovalState.errorTilesOutsideOfKeepMargin()) {
          _remove(tileImage.coordinatesKey, evictImageFromCache: (_) => true);
        }
      case EvictErrorTileStrategy.notVisible:
        for (final tileImage in tileRemovalState.errorTilesNotVisible()) {
          _remove(tileImage.coordinatesKey, evictImageFromCache: (_) => true);
        }
      case EvictErrorTileStrategy.dispose:
      case EvictErrorTileStrategy.none:
        return;
    }
  }

  void prune({
    required DiscreteTileRange visibleRange,
    required int pruneBuffer,
    required EvictErrorTileStrategy evictStrategy,
  }) {
    _prune(
      TileImageView(
        tileImages: _tiles,
        visibleRange: visibleRange,
        keepRange: visibleRange.expand(pruneBuffer),
      ),
      evictStrategy,
    );
  }

  void _prune(
    TileImageView tileRemovalState,
    EvictErrorTileStrategy evictStrategy,
  ) {
    for (final tileImage in tileRemovalState.staleTiles()) {
      _removeWithEvictionStrategy(tileImage.coordinatesKey, evictStrategy);
    }
  }
}
