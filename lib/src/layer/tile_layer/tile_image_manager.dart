import 'package:collection/collection.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds/tile_bounds.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds/tile_bounds_at_zoom.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_display.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:flutter_map/src/misc/point.dart';

typedef TileCreator = TileImage Function(TileCoordinates coordinates);

class TileImageManager {
  final Map<String, TileImage> _tiles = {};

  bool containsTileAt(TileCoordinates coordinates) =>
      _tiles.containsKey(coordinates.key);

  bool get allLoaded =>
      _tiles.values.none((tile) => tile.loadFinishedAt == null);

  // Returns in the order in which they should be rendered:
  //   1. Tiles at the current zoom.
  //   2. Tiles at the current zoom +/- 1.
  //   3. Tiles at the current zoom +/- 2.
  //   4. ...etc
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

  bool allWithinZoom(double minZoom, double maxZoom) {
    for (final tile in _tiles.values) {
      if (tile.coordinates.z > (maxZoom) || tile.coordinates.z < (minZoom)) {
        return false;
      }
    }
    return true;
  }

  // For all of the tile coordinates:
  //   * A TileImage is created if missing (current = true in new TileImages)
  //   * If it exists current is set to true
  //   * Of these tiles, those which have not started loading yet are returned.
  List<TileImage> setCurrentAndReturnNotLoadedTiles(
    Iterable<TileCoordinates> tileCoordinates, {
    required TileCreator createTile,
  }) {
    final notLoaded = <TileImage>[];

    for (final coordinates in tileCoordinates) {
      final tile = _tiles.putIfAbsent(
        coordinates.key,
        () => createTile(coordinates),
      );

      tile.current = true;
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

  void _removeWithDefaultEviction(String key, EvictErrorTileStrategy strategy) {
    _remove(
      key,
      evictImageFromCache: (tileImage) =>
          tileImage.loadError && strategy != EvictErrorTileStrategy.none,
    );
  }

  void removeAll(EvictErrorTileStrategy evictStrategy) {
    final toRemove = Map<String, TileImage>.from(_tiles);

    for (final key in toRemove.keys) {
      _removeWithDefaultEviction(key, evictStrategy);
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

  void markAsNoLongerCurrentOutside(
      int currentTileZoom, DiscreteTileRange noPruneRange) {
    for (final entry in _tiles.entries) {
      final tile = entry.value;
      final c = tile.coordinates;

      if (tile.current &&
          (c.z != currentTileZoom ||
              !noPruneRange.contains(CustomPoint(c.x, c.y)))) {
        tile.current = false;
      }
    }
  }

  // Evicts error tiles depending on the [evictStrategy].
  void evictErrorTiles(
    DiscreteTileRange tileRange,
    EvictErrorTileStrategy evictStrategy,
  ) {
    if (evictStrategy == EvictErrorTileStrategy.notVisibleRespectMargin) {
      final toRemove = <String>[];
      for (final entry in _tiles.entries) {
        final tile = entry.value;

        if (tile.loadError && !tile.current) {
          toRemove.add(entry.key);
        }
      }

      for (final key in toRemove) {
        _remove(key, evictImageFromCache: (_) => true);
      }
    } else if (evictStrategy == EvictErrorTileStrategy.notVisible) {
      final toRemove = <String>[];
      for (final entry in _tiles.entries) {
        final tile = entry.value;
        final c = tile.coordinates;

        if (tile.loadError &&
            (!tile.current || !tileRange.contains(CustomPoint(c.x, c.y)))) {
          toRemove.add(entry.key);
        }
      }

      for (final key in toRemove) {
        _remove(key, evictImageFromCache: (_) => true);
      }
    }
  }

  void prune(EvictErrorTileStrategy evictStrategy) {
    for (final tile in _tiles.values) {
      tile.retain = tile.current;
    }

    for (final tile in _tiles.values) {
      if (tile.current && !tile.active) {
        final coords = tile.coordinates;
        if (!_retainAncestor(coords.x, coords.y, coords.z, coords.z - 5)) {
          _retainChildren(coords.x, coords.y, coords.z, coords.z + 2);
        }
      }
    }

    final toRemove = <String>[];
    for (final entry in _tiles.entries) {
      if (!entry.value.retain) toRemove.add(entry.key);
    }

    for (final key in toRemove) {
      _removeWithDefaultEviction(key, evictStrategy);
    }
  }

  // Recurses through the descendants of the Tile at the given coordinates
  // setting their [Tile.retain] to true if they are active or loaded. Returns
  /// true if any of the descendant tiles were retained.
  void _retainChildren(int x, int y, int z, int maxZoom) {
    for (var i = 2 * x; i < 2 * x + 2; i++) {
      for (var j = 2 * y; j < 2 * y + 2; j++) {
        final coords = TileCoordinates(i, j, z + 1);

        final tile = _tiles[coords.key];
        if (tile != null) {
          if (tile.active) {
            tile.retain = true;
            continue;
          } else if (tile.loadFinishedAt != null) {
            tile.retain = true;
          }
        }

        if (z + 1 < maxZoom) {
          _retainChildren(i, j, z + 1, maxZoom);
        }
      }
    }
  }

  // Recurses through the ancestors of the Tile at the given coordinates setting
  // their [Tile.retain] to true if they are active or loaded. Returns true if
  // any of the ancestor tiles were active.
  bool _retainAncestor(int x, int y, int z, int minZoom) {
    final x2 = (x / 2).floor();
    final y2 = (y / 2).floor();
    final z2 = z - 1;
    final coords2 = TileCoordinates(x2, y2, z2);

    final tile = _tiles[coords2.key];
    if (tile != null) {
      if (tile.active) {
        tile.retain = true;
        return true;
      } else if (tile.loadFinishedAt != null) {
        tile.retain = true;
      }
    }

    if (z2 > minZoom) {
      return _retainAncestor(x2, y2, z2, minZoom);
    }

    return false;
  }
}
