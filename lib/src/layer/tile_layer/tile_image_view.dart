import 'dart:collection';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';

/// The [TileImageView] stores all loaded [TileImage]s with their
/// [TileCoordinates].
final class TileImageView {
  final Map<TileCoordinates, TileImage> _tileImages;
  final DiscreteTileRange _visibleRange;
  final DiscreteTileRange _keepRange;

  /// Create a new [TileImageView] instance.
  const TileImageView({
    required Map<TileCoordinates, TileImage> tileImages,
    required DiscreteTileRange visibleRange,
    required DiscreteTileRange keepRange,
  })  : _tileImages = tileImages,
        _visibleRange = visibleRange,
        _keepRange = keepRange;

  /// Get a list with all tiles that have an error and are outside of the
  /// margin that should get kept.
  List<TileImage> errorTilesOutsideOfKeepMargin() => _tileImages.values
      .where((tileImage) =>
          tileImage.loadError && !_keepRange.contains(tileImage.coordinates))
      .toList();

  /// Get a list with all tiles that are not visible on the current map
  /// viewport.
  List<TileImage> errorTilesNotVisible() => _tileImages.values
      .where((tileImage) =>
          tileImage.loadError && !_visibleRange.contains(tileImage.coordinates))
      .toList();

  /// Get a list of [TileImage] that are stale and can get for pruned.
  Iterable<TileImage> get staleTiles {
    final stale = HashSet<TileImage>();
    final retain = HashSet<TileImage>();

    for (final tile in _tileImages.values) {
      final c = tile.coordinates;
      if (!_keepRange.contains(c)) {
        stale.add(tile);
        continue;
      }

      final retainedAncestor = _retainAncestor(retain, c.x, c.y, c.z, c.z - 5);
      if (!retainedAncestor) {
        _retainChildren(retain, c.x, c.y, c.z, c.z + 2);
      }
    }

    return stale.where((tile) => !retain.contains(tile));
  }

  /// Get a list of [TileImage] that need to get rendered on screen.
  Iterable<TileImage> get renderTiles {
    final retain = HashSet<TileImage>();

    for (final tile in _tileImages.values) {
      final c = tile.coordinates;
      if (!_visibleRange.contains(c)) {
        continue;
      }

      retain.add(tile);

      if (!tile.readyToDisplay) {
        final retainedAncestor =
            _retainAncestor(retain, c.x, c.y, c.z, c.z - 5);
        if (!retainedAncestor) {
          _retainChildren(retain, c.x, c.y, c.z, c.z + 2);
        }
      }
    }
    return retain;
  }

  /// Recurse through the ancestors of the Tile at the given coordinates adding
  /// them to [retain] if they are ready to display or loaded. Returns true if
  /// any of the ancestor tiles were ready to display.
  bool _retainAncestor(
    Set<TileImage> retain,
    int x,
    int y,
    int z,
    int minZoom,
  ) {
    final x2 = (x / 2).floor();
    final y2 = (y / 2).floor();
    final z2 = z - 1;
    final coords2 = TileCoordinates(x2, y2, z2);

    final tile = _tileImages[coords2];
    if (tile != null) {
      if (tile.readyToDisplay) {
        retain.add(tile);
        return true;
      } else if (tile.loadFinishedAt != null) {
        retain.add(tile);
      }
    }

    if (z2 > minZoom) {
      return _retainAncestor(retain, x2, y2, z2, minZoom);
    }

    return false;
  }

  /// Recurse through the descendants of the Tile at the given coordinates
  /// adding them to [retain] if they are ready to display or loaded.
  void _retainChildren(
    Set<TileImage> retain,
    int x,
    int y,
    int z,
    int maxZoom,
  ) {
    for (final (i, j) in const [(0, 0), (0, 1), (1, 0), (1, 1)]) {
      final coords = TileCoordinates(2 * x + i, 2 * y + j, z + 1);

      final tile = _tileImages[coords];
      if (tile != null) {
        if (tile.readyToDisplay || tile.loadFinishedAt != null) {
          retain.add(tile);

          // If have the child, we do not recurse. We don't need the child's children.
          continue;
        }
      }

      if (z + 1 < maxZoom) {
        _retainChildren(retain, i, j, z + 1, maxZoom);
      }
    }
  }
}
