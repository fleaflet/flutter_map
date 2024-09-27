import 'dart:collection';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';

/// The [TileImageView] stores all loaded [TileImage]s with their
/// [TileCoordinates].
final class TileImageView {
  final Map<TileCoordinates, TileImage> _tileImages;
  final Set<TileCoordinates> _positionCoordinates;
  final DiscreteTileRange _visibleRange;
  final DiscreteTileRange _keepRange;

  /// Create a new [TileImageView] instance.
  const TileImageView({
    required Map<TileCoordinates, TileImage> tileImages,
    required Set<TileCoordinates> positionCoordinates,
    required DiscreteTileRange visibleRange,
    required DiscreteTileRange keepRange,
  })  : _tileImages = tileImages,
        _positionCoordinates = positionCoordinates,
        _visibleRange = visibleRange,
        _keepRange = keepRange;

  /// Get a list with all tiles that have an error and are outside of the
  /// margin that should get kept.
  List<TileCoordinates> errorTilesOutsideOfKeepMargin() =>
      _errorTilesWithinRange(_keepRange);

  /// Get a list with all tiles that are not visible on the current map
  /// viewport.
  List<TileCoordinates> errorTilesNotVisible() =>
      _errorTilesWithinRange(_visibleRange);

  /// Get a list with all tiles that are not visible on the current map
  /// viewport.
  List<TileCoordinates> _errorTilesWithinRange(DiscreteTileRange range) {
    final List<TileCoordinates> result = <TileCoordinates>[];
    for (final positionCoordinates in _positionCoordinates) {
      if (range.contains(positionCoordinates)) {
        continue;
      }
      final TileImage? tileImage =
          _tileImages[TileCoordinates.key(positionCoordinates)];
      if (tileImage?.loadError ?? false) {
        result.add(positionCoordinates);
      }
    }
    return result;
  }

  /// Get a list of [TileImage] that are stale and can get for pruned.
  Iterable<TileCoordinates> get staleTiles {
    final stale = HashSet<TileCoordinates>();
    final retain = HashSet<TileCoordinates>();

    for (final positionCoordinates in _positionCoordinates) {
      if (!_keepRange.contains(positionCoordinates)) {
        stale.add(positionCoordinates);
        continue;
      }

      final retainedAncestor = _retainAncestor(
        retain,
        positionCoordinates.x,
        positionCoordinates.y,
        positionCoordinates.z,
        positionCoordinates.z - 5,
      );
      if (!retainedAncestor) {
        _retainChildren(
          retain,
          positionCoordinates.x,
          positionCoordinates.y,
          positionCoordinates.z,
          positionCoordinates.z + 2,
        );
      }
    }

    return stale.where((tile) => !retain.contains(tile));
  }

  /// Get a list of [TileCoordinates] that need to get rendered on screen.
  Iterable<TileCoordinates> get renderTiles {
    final retain = HashSet<TileCoordinates>();

    for (final positionCoordinates in _positionCoordinates) {
      if (!_visibleRange.contains(positionCoordinates)) {
        continue;
      }

      retain.add(positionCoordinates);

      final TileImage? tile =
          _tileImages[TileCoordinates.key(positionCoordinates)];
      if (tile == null || !tile.readyToDisplay) {
        final retainedAncestor = _retainAncestor(
          retain,
          positionCoordinates.x,
          positionCoordinates.y,
          positionCoordinates.z,
          positionCoordinates.z - 5,
        );
        if (!retainedAncestor) {
          _retainChildren(
            retain,
            positionCoordinates.x,
            positionCoordinates.y,
            positionCoordinates.z,
            positionCoordinates.z + 2,
          );
        }
      }
    }
    return retain;
  }

  /// Recurse through the ancestors of the Tile at the given coordinates adding
  /// them to [retain] if they are ready to display or loaded. Returns true if
  /// any of the ancestor tiles were ready to display.
  bool _retainAncestor(
    Set<TileCoordinates> retain,
    int x,
    int y,
    int z,
    int minZoom,
  ) {
    final x2 = (x / 2).floor();
    final y2 = (y / 2).floor();
    final z2 = z - 1;
    final coords2 = TileCoordinates(x2, y2, z2);

    final tile = _tileImages[TileCoordinates.key(coords2)];
    if (tile != null) {
      if (tile.readyToDisplay) {
        retain.add(coords2);
        return true;
      } else if (tile.loadFinishedAt != null) {
        retain.add(coords2);
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
    Set<TileCoordinates> retain,
    int x,
    int y,
    int z,
    int maxZoom,
  ) {
    for (final (i, j) in const [(0, 0), (0, 1), (1, 0), (1, 1)]) {
      final coords = TileCoordinates(2 * x + i, 2 * y + j, z + 1);

      final tile = _tileImages[TileCoordinates.key(coords)];
      if (tile != null) {
        if (tile.readyToDisplay || tile.loadFinishedAt != null) {
          retain.add(coords);

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
