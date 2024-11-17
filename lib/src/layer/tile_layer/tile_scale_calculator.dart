import 'package:flutter_map/flutter_map.dart';

/// Calculate a scale value to transform the Tile's coordinate to its position.
class TileScaleCalculator {
  /// Reference to the used coordinate reference system.
  final Crs crs;

  /// The size in pixel of tiles.
  final int tileDimension;

  double? _cachedCurrentZoom;
  final Map<int, double> _cache = {};

  /// Create a new [TileScaleCalculator] instance.
  TileScaleCalculator({
    required this.crs,
    required this.tileDimension,
  });

  /// Returns true to indicate that the TileDimensionCache should get replaced.
  bool shouldReplace(Crs crs, int tileDimension) =>
      this.crs != crs || this.tileDimension != tileDimension;

  /// Clears the cache if the zoom level does not match the current cached one
  /// and sets [currentZoom] as the new zoom to cache for.
  ///
  /// Must be called before calling [scaledTileDimension] with a [currentZoom]
  /// different than the last time [scaledTileDimension] was called.
  void clearCacheUnlessZoomMatches(double currentZoom) {
    if (_cachedCurrentZoom != currentZoom) _cache.clear();
    _cachedCurrentZoom = currentZoom;
  }

  /// Returns a scale value to transform a Tile coordinate to a Tile position.
  double scaledTileDimension(double currentZoom, int tileZoom) {
    assert(
      _cachedCurrentZoom == currentZoom,
      'The cachedCurrentZoom value and the provided currentZoom need to be equal',
    );
    return _cache.putIfAbsent(
      tileZoom,
      () => _scaledTileDimensionImpl(currentZoom, tileZoom),
    );
  }

  double _scaledTileDimensionImpl(double currentZoom, int tileZoom) {
    return tileDimension *
        (crs.scale(currentZoom) / crs.scale(tileZoom.toDouble()));
  }
}
