import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/layer/tile_layer/tile.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinate.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';

class TileManager {
  final Map<String, Tile> _tiles = {};

  List<Tile> all() => _tiles.values.toList();

  List<Tile> sortedByDistanceToZoomAscending(double maxZoom, int currentZoom) {
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

  Tile? tileAt(TileCoordinate coords) => _tiles[coords.key];

  bool get allLoaded {
    for (final entry in _tiles.entries) {
      if (entry.value.loaded == null) {
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

  void add(TileCoordinate coords, Tile tile) {
    _tiles[coords.key] = tile;

    // This must be done after storing the Tile in the TileManager otherwise
    // the callbacks for image load success/fail will not find this Tile in
    // the TileManager.
    tile.loadTileImage();
  }

  void remove(String key, EvictErrorTileStrategy evictStrategy) {
    final tile = _tiles[key];
    if (tile == null) {
      return;
    }

    tile.dispose(
        tile.loadError && evictStrategy != EvictErrorTileStrategy.none);

    _tiles.remove(key);
  }

  void removeAll(EvictErrorTileStrategy evictStrategy) {
    final toRemove = Map<String, Tile>.from(_tiles);

    for (final key in toRemove.keys) {
      remove(key, evictStrategy);
    }
  }

  void removeAtZoom(double zoom, EvictErrorTileStrategy evictStrategy) {
    final toRemove = <String>[];
    for (final entry in _tiles.entries) {
      if (entry.value.coordinate.z != zoom) {
        continue;
      }
      toRemove.add(entry.key);
    }

    for (final key in toRemove) {
      remove(key, evictStrategy);
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

      if (tile.coordinate.z != tileZoom && tile.loaded == null) {
        toRemove.add(entry.key);
      }
    }

    for (final key in toRemove) {
      final tile = _tiles[key]!;

      tile.tileReady = null;
      tile.dispose(
          tile.loadError && evictionStrategy != EvictErrorTileStrategy.none);
      _tiles.remove(key);
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
        _tiles[key]!.dispose(true);
        _tiles.remove(key);
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
        _tiles[key]!.dispose(true);
        _tiles.remove(key);
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
      remove(key, evictStrategy);
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
          } else if (tile.loaded != null) {
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
      } else if (tile.loaded != null) {
        tile.retain = true;
      }
    }

    if (z2 > minZoom) {
      return _retainAncestor(x2, y2, z2, minZoom);
    }

    return false;
  }
}
