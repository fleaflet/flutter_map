import 'dart:collection';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_bounds/tile_bounds.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range.dart';
import 'package:flutter_map/src/misc/bounds.dart';

/// A set of tiles, at one or more zooms.
abstract interface class TileCover {
  /// The cover of exactly [tiles]. [expand] doesn't add the tiles for which
  /// [isCovered] is true: tiles that [tiles] cover at another zoom.
  factory TileCover(
    Iterable<TileCoordinates> tiles, {
    bool Function(TileCoordinates tile)? isCovered,
  }) = _TileSet;

  /// Whether this cover contains [point], a [TileCoordinates] whose zoom is
  /// compared as well as its x and y.
  ///
  /// If [replicatesWorldLongitude] is true, x is compared modulo the number of
  /// tiles at that zoom.
  bool contains(TileCoordinates point, {bool replicatesWorldLongitude = false});

  /// This cover and every tile within [count] tiles of one of its tiles, at
  /// that tile's zoom, except tiles that this cover covers at another zoom.
  TileCover expand(int count);

  /// The tiles of this cover.
  Iterable<TileCoordinates> get coordinates;

  /// The tiles of this cover that are valid within [bounds].
  Iterable<TileCoordinates> validCoordinatesIn(TileBounds bounds);
}

class _TileSet implements TileCover {
  final Set<TileCoordinates> _tiles;

  /// [_tiles] with x wrapped into the world, created when first needed.
  Set<TileCoordinates>? _wrappedTiles;

  final bool Function(TileCoordinates tile)? _isCovered;
  final _expansions = <int, TileCover>{};

  _TileSet(
    Iterable<TileCoordinates> tiles, {
    bool Function(TileCoordinates tile)? isCovered,
  })  : _tiles = LinkedHashSet<TileCoordinates>.of(tiles),
        _isCovered = isCovered;

  @override
  bool contains(
    TileCoordinates point, {
    bool replicatesWorldLongitude = false,
  }) {
    if (!replicatesWorldLongitude) return _tiles.contains(point);
    return (_wrappedTiles ??= {for (final tile in _tiles) _wrapX(tile)})
        .contains(_wrapX(point));
  }

  static TileCoordinates _wrapX(TileCoordinates tile) =>
      TileCoordinates(tile.x % (1 << tile.z), tile.y, tile.z);

  @override
  TileCover expand(int count) =>
      count == 0 ? this : _expansions.putIfAbsent(count, () => _expand(count));

  TileCover _expand(int count) {
    final expanded = LinkedHashSet<TileCoordinates>.of(_tiles);
    for (final tile in _tiles) {
      for (var y = tile.y - count; y <= tile.y + count; y++) {
        for (var x = tile.x - count; x <= tile.x + count; x++) {
          final neighbor = TileCoordinates(x, y, tile.z);
          if (_tiles.contains(neighbor) ||
              (_isCovered?.call(neighbor) ?? false)) {
            continue;
          }
          expanded.add(neighbor);
        }
      }
    }
    return _TileSet(expanded, isCovered: _isCovered);
  }

  @override
  Iterable<TileCoordinates> get coordinates => _tiles;

  @override
  Iterable<TileCoordinates> validCoordinatesIn(TileBounds bounds) =>
      _tiles.where((tile) => bounds
          .atZoom(tile.z)
          .validCoordinatesIn(
              DiscreteTileRange(tile.z, IntegerBounds(tile, tile)))
          .isNotEmpty);

  @override
  String toString() => 'TileCover(${_tiles.length} tiles)';
}
