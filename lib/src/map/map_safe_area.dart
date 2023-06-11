import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:latlong2/latlong.dart';

class MapSafeArea {
  final LatLngBounds bounds;
  final double zoom;
  final bool _isLatitudeBlocked;
  final bool _isLongitudeBlocked;

  MapSafeArea._({
    required this.bounds,
    required this.zoom,
  })  : _isLatitudeBlocked = bounds.south > bounds.north,
        _isLongitudeBlocked = bounds.west > bounds.east;

  factory MapSafeArea({
    required Size screenSize,
    required LatLngBounds bounds,
    required double zoom,
  }) {
    final halfScreenHeightDeg = _halfScreenHeightDegrees(screenSize, zoom);
    final halfScreenWidthDeg = _halfScreenWidthDegrees(screenSize, zoom);

    final safeBounds = LatLngBounds(
      LatLng(
        bounds.north - halfScreenHeightDeg,
        bounds.east - halfScreenWidthDeg,
      ),
      LatLng(
        bounds.south + halfScreenHeightDeg,
        bounds.west + halfScreenWidthDeg,
      ),
    );

    return MapSafeArea._(
      bounds: safeBounds,
      zoom: zoom,
    );
  }

  bool contains(LatLng point) =>
      _isLatitudeBlocked || _isLongitudeBlocked ? false : bounds.contains(point);

  LatLng clampWithFallback(LatLng point, LatLng fallback) => LatLng(
        _isLatitudeBlocked
            ? fallback.latitude
            : point.latitude.clamp(bounds.south, bounds.north),
        _isLongitudeBlocked
            ? fallback.longitude
            : point.longitude.clamp(bounds.west, bounds.east),
      );

  static double _halfScreenWidthDegrees(
    Size screenSize,
    double zoom,
  ) {
    final degreesPerPixel = 360 / math.pow(2, zoom + 8);
    return (screenSize.width * degreesPerPixel) / 2;
  }

  static double _halfScreenHeightDegrees(
    Size screenSize,
    double zoom,
  ) =>
      (screenSize.height * 170.102258 / math.pow(2, zoom + 8)) / 2;
}
