import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:latlong2/latlong.dart';

class MapSafeArea {
  final LatLngBounds bounds;
  final bool isLatitudeBlocked;
  final bool isLongitudeBlocked;

  final double _zoom;
  final Size _screenSize;
  final LatLng _swPanBoundary;
  final LatLng _nePanBoundary;

  MapSafeArea({
    required LatLng southWest,
    required LatLng northEast,
    required double zoom,
    required Size screenSize,
    required LatLng swPanBoundary,
    required LatLng nePanBoundary,
  })  : bounds = LatLngBounds(southWest, northEast),
        isLatitudeBlocked = southWest.latitude > northEast.latitude,
        isLongitudeBlocked = southWest.longitude > northEast.longitude,
        _zoom = zoom,
        _screenSize = screenSize,
        _swPanBoundary = swPanBoundary,
        _nePanBoundary = nePanBoundary;

  factory MapSafeArea.createUnlessMatching({
    MapSafeArea? previous,
    required double zoom,
    required Size screenSize,
    required LatLng swPanBoundary,
    required LatLng nePanBoundary,
  }) {
    if (previous == null ||
        previous._zoom != zoom ||
        previous._screenSize != screenSize ||
        previous._swPanBoundary != swPanBoundary ||
        previous._nePanBoundary != nePanBoundary) {
      final halfScreenHeightDeg = _halfScreenHeightDegrees(screenSize, zoom);
      final halfScreenWidthDeg = _halfScreenWidthDegrees(screenSize, zoom);

      final southWestLatitude = swPanBoundary.latitude + halfScreenHeightDeg;
      final southWestLongitude = swPanBoundary.longitude + halfScreenWidthDeg;
      final northEastLatitude = nePanBoundary.latitude - halfScreenHeightDeg;
      final northEastLongitude = nePanBoundary.longitude - halfScreenWidthDeg;

      return MapSafeArea(
        southWest: LatLng(southWestLatitude, southWestLongitude),
        northEast: LatLng(northEastLatitude, northEastLongitude),
        zoom: zoom,
        screenSize: screenSize,
        swPanBoundary: swPanBoundary,
        nePanBoundary: nePanBoundary,
      );
    }
    return previous;
  }

  bool contains(LatLng point) =>
      isLatitudeBlocked || isLongitudeBlocked ? false : bounds.contains(point);

  LatLng containPoint(LatLng point, LatLng fallback) => LatLng(
        isLatitudeBlocked
            ? fallback.latitude
            : point.latitude.clamp(bounds.south, bounds.north),
        isLongitudeBlocked
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
