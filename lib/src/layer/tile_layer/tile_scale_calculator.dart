import 'package:flutter_map/flutter_map.dart';

/// Calculate a scale value to transform the Tile's coordinate to its position.
class TileScaleCalculator {
  final Crs crs;
  final double tileSize;

  double? _cachedCurrentZoom;
  final Map<int, double> _cache = {};

  TileScaleCalculator({
    required this.crs,
    required this.tileSize,
  });

  /// If [true] indicates that the TileSizeCache should be replaced.
  bool shouldReplace(Crs crs, double tileSize) =>
      this.crs != crs || this.tileSize != tileSize;

  /// Clears the cache if the zoom level does not match the current cached one
  /// and sets [currentZoom] as the new zoom to cache for. Must be called
  /// before calling scaledTileSize with a [currentZoom] different than the
  /// last time scaledTileSize was called.
  void clearCacheUnlessZoomMatches(double currentZoom) {
    if (_cachedCurrentZoom != currentZoom) _cache.clear();
    _cachedCurrentZoom = currentZoom;
  }

  /// Returns a scale value to transform a Tile coordainte to a Tile position.
  double scaledTileSize(double currentZoom, int tileZoom) {
    assert(
      _cachedCurrentZoom == currentZoom,
      'The cachedCurrentZoom value and the provided currentZoom need to be equal',
    );
    return _cache.putIfAbsent(
      tileZoom,
      () => _scaledTileSizeImpl(currentZoom, tileZoom),
    );
  }

  double _scaledTileSizeImpl(double currentZoom, int tileZoom) {
    return tileSize * (crs.scale(currentZoom) / crs.scale(tileZoom.toDouble()));
  }
}
