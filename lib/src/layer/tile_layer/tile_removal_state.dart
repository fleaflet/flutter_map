import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';

class TileRemovalState {
  final EvictErrorTileStrategy evictStrategy;
  final Map<TileCoordinates, TileImage> _tileImages;
  final DiscreteTileRange _visibleRange;
  final DiscreteTileRange _keepRange;

  Set<TileImage>? _visibleTilesMemo;
  Set<TileImage>? _keepTilesMemo;

  TileRemovalState({
    required Iterable<TileImage> tileImages,
    required DiscreteTileRange visibleRange,
    required DiscreteTileRange keepRange,
    required this.evictStrategy,
  })  : _tileImages = Map.unmodifiable({
          for (var tileImage in tileImages) tileImage.coordinates: tileImage
        }),
        _visibleRange = visibleRange,
        _keepRange = keepRange;

  Set<TileImage> get _visibleTiles =>
      _visibleTilesMemo ??= Set.unmodifiable(_tileImages.values
          .where((tileImage) => _visibleRange.contains(tileImage.coordinates))
          .toSet());

  Set<TileImage> get _keepTiles =>
      _keepTilesMemo ??= Set.unmodifiable(_tileImages.values
          .where((tileImage) => _keepRange.contains(tileImage.coordinates))
          .toSet());

  List<TileImage> errorTilesToEvict() {
    switch (evictStrategy) {
      case EvictErrorTileStrategy.notVisibleRespectMargin:
        return _tileImages.values
            .where((tileImage) => !_keepTiles.contains(tileImage))
            .toList();
      case EvictErrorTileStrategy.notVisible:
        return _tileImages.values
            .where((tileImage) => !_visibleTiles.contains(tileImage))
            .toList();
      case EvictErrorTileStrategy.dispose:
      case EvictErrorTileStrategy.none:
        return const [];
    }
  }

  List<TileImage> tilesToPrune() {
    final retain = Set<TileImage>.from(_keepTiles);

    for (final tile in _tileImages.values) {
      if (_keepTiles.contains(tile) && !tile.readyToDisplay) {
        final coords = tile.coordinates;
        if (!_retainAncestor(
            retain, coords.x, coords.y, coords.z, coords.z - 5)) {
          _retainChildren(retain, coords.x, coords.y, coords.z, coords.z + 2);
        }
      }
    }

    return _tileImages.values
        .where((tileImage) => !retain.contains(tileImage))
        .toList();
  }

  // Recurses through the ancestors of the Tile at the given coordinates adding
  // them to [retain] if they are ready to display or loaded. Returns true if
  // any of the ancestor tiles were ready to display.
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

  // Recurses through the descendants of the Tile at the given coordinates
  // adding them to [retain] if they are ready to display or loaded.
  void _retainChildren(
    Set<TileImage> retain,
    int x,
    int y,
    int z,
    int maxZoom,
  ) {
    for (var i = 2 * x; i < 2 * x + 2; i++) {
      for (var j = 2 * y; j < 2 * y + 2; j++) {
        final coords = TileCoordinates(i, j, z + 1);

        final tile = _tileImages[coords];
        if (tile != null) {
          if (tile.readyToDisplay || tile.loadFinishedAt != null) {
            retain.add(tile);
          }
        }

        if (z + 1 < maxZoom) {
          _retainChildren(retain, i, j, z + 1, maxZoom);
        }
      }
    }
  }
}
