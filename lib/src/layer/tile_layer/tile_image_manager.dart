import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds/tile_bounds.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinate.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';

class TileImageManager {
  final Map<String, TileImage> _tiles = {};

  List<TileImage> all() => _tiles.values.toList();

  List<TileImage> sortedByDistanceToZoomAscending(
      double maxZoom, int currentZoom) {
    return [..._tiles.values]..sort((a, b) => a
        .zIndex(maxZoom, currentZoom)
        .compareTo(b.zIndex(maxZoom, currentZoom)));
  }

  bool anyWithZoomLevel(double zoomLevel) {
    for (final tile in _tiles.values) {
      if (tile.coordinate.z == zoomLevel) {
        return true;
      }
    }

    return false;
  }

  TileImage? tileAt(TileCoordinate coords) => _tiles[coords.key];

  bool get allLoaded {
    for (final entry in _tiles.entries) {
      if (entry.value.loadFinishedAt == null) {
        return false;
      }
    }
    return true;
  }

  bool allWithinZoom(double minZoom, double maxZoom) {
    for (final tile in _tiles.values) {
      if (tile.coordinate.z > (maxZoom) || tile.coordinate.z < (minZoom)) {
        return false;
      }
    }
    return true;
  }

  bool markTileWithCoordsAsCurrent(TileCoordinate coords) {
    final tile = _tiles[coords.key];
    if (tile != null) {
      tile.current = true;
      return true;
    } else {
      return false;
    }
  }

  void add(TileCoordinate coords, TileImage tile) {
    _tiles[coords.key] = tile;

    // This must be done after storing the Tile in the TileManager otherwise
    // the callbacks for image load success/fail will not find this Tile in
    // the TileManager.
    tile.loadTileImage();
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
    for (final tile in _tiles.values) {
      tile.imageProvider = layer.tileProvider.getImage(
        tileBounds.atZoom(tile.coordinate.z).wrap(tile.coordinate),
        layer,
      );
      tile.loadTileImage();
    }
  }

  void abortLoading(int? tileZoom, EvictErrorTileStrategy evictionStrategy) {
    final toRemove = <String>[];
    for (final entry in _tiles.entries) {
      final tile = entry.value;

      if (tile.coordinate.z != tileZoom && tile.loadFinishedAt == null) {
        toRemove.add(entry.key);
      }
    }

    for (final key in toRemove) {
      _removeWithDefaultEviction(key, evictionStrategy);
    }
  }

  void markToPrune(int currentTileZoom, DiscreteTileRange noPruneRange) {
    for (final entry in _tiles.entries) {
      final tile = entry.value;
      final c = tile.coordinate;

      if (tile.current &&
          (c.z != currentTileZoom ||
              !noPruneRange.contains(CustomPoint(c.x, c.y)))) {
        tile.current = false;
      }
    }
  }

  void evictErrorTilesBasedOnStrategy(
      DiscreteTileRange tileRange, EvictErrorTileStrategy evictStrategy) {
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
        final c = tile.coordinate;

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
        final coords = tile.coordinate;
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
        final coords = TileCoordinate(i, j, z + 1);

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
    final coords2 = TileCoordinate(x2, y2, z2);

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
