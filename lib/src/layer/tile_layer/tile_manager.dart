import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:tuple/tuple.dart';

class TileManager {
  final Map<String, Tile> _tiles = {};

  List<Tile> all() => _tiles.values.toList();

  List<Tile> sortedByDistanceToZoomAscending(
      double maxZoom, double currentZoom) {
    return [..._tiles.values]..sort((a, b) => a
        .zIndex(maxZoom, currentZoom)
        .compareTo(b.zIndex(maxZoom, currentZoom)));
  }

  bool anyWithZoomLevel(double zoomLevel) {
    for (final tile in _tiles.values) {
      if (tile.coords.z == zoomLevel) {
        return true;
      }
    }

    return false;
  }

  Tile? tileAt(Coords coords) => _tiles[coords.key];

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
      if (tile.coords.z > (maxZoom) || tile.coords.z < (minZoom)) {
        return false;
      }
    }
    return true;
  }

  bool markTileWithCoordsAsCurrent(Coords coords) {
    final tile = _tiles[coords.key];
    if (tile != null) {
      tile.current = true;
      return true;
    } else {
      return false;
    }
  }

  void add(Coords<double> coords, Tile tile) {
    _tiles[coords.key] = tile;
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
      if (entry.value.coords.z != zoom) {
        continue;
      }
      toRemove.add(entry.key);
    }

    for (final key in toRemove) {
      remove(key, evictStrategy);
    }
  }

  void reloadImages(
    TileLayerOptions options,
    Tuple2<double, double>? wrapX,
    Tuple2<double, double>? wrapY,
  ) {
    for (final tile in _tiles.values) {
      tile.imageProvider = options.tileProvider
          .getImage(tile.coords.wrap(wrapX, wrapY), options);
      tile.loadTileImage();
    }
  }

  void abortLoading(double? tileZoom, EvictErrorTileStrategy evictionStrategy) {
    final toRemove = <String>[];
    for (final entry in _tiles.entries) {
      final tile = entry.value;

      if (tile.coords.z != tileZoom && tile.loaded == null) {
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

  void markToPrune(double? currentZoom, Bounds noPruneRange) {
    for (final entry in _tiles.entries) {
      final tile = entry.value;
      final c = tile.coords;

      if (tile.current &&
          (c.z != currentZoom ||
              !noPruneRange.contains(CustomPoint(c.x, c.y)))) {
        tile.current = false;
      }
    }
  }

  void evictErrorTilesBasedOnStrategy(
      Bounds tileRange, EvictErrorTileStrategy evictStrategy) {
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
        final c = tile.coords;

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

  void prune(double? zoom, EvictErrorTileStrategy evictStrategy) {
    if (zoom == null) {
      removeAll(evictStrategy);
      return;
    }

    for (final entry in _tiles.entries) {
      final tile = entry.value;
      tile.retain = tile.current;
    }

    for (final entry in _tiles.entries) {
      final tile = entry.value;

      if (tile.current && !tile.active) {
        final coords = tile.coords;
        if (!_retainParent(coords.x, coords.y, coords.z, coords.z - 5)) {
          _retainChildren(coords.x, coords.y, coords.z, coords.z + 2);
        }
      }
    }

    final toRemove = <String>[];
    for (final entry in _tiles.entries) {
      final tile = entry.value;

      if (!tile.retain) {
        toRemove.add(entry.key);
      }
    }

    for (final key in toRemove) {
      remove(key, evictStrategy);
    }
  }

  void _retainChildren(double x, double y, double z, double maxZoom) {
    for (var i = 2 * x; i < 2 * x + 2; i++) {
      for (var j = 2 * y; j < 2 * y + 2; j++) {
        final coords = Coords(i, j);
        coords.z = z + 1;

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

  bool _retainParent(double x, double y, double z, double minZoom) {
    final x2 = (x / 2).floorToDouble();
    final y2 = (y / 2).floorToDouble();
    final z2 = z - 1;
    final coords2 = Coords(x2, y2);
    coords2.z = z2;

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
      return _retainParent(x2, y2, z2, minZoom);
    }

    return false;
  }
}
