import 'dart:math' as math;

import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

abstract class MapBoundary {
  const MapBoundary();

  CenterZoom? clampCenterZoom({
    required Crs crs,
    required CustomPoint<double> visibleSize,
    required CenterZoom centerZoom,
  });
}

class CrsBoundary extends MapBoundary {
  const CrsBoundary();

  @override
  CenterZoom clampCenterZoom({
    required Crs crs,
    required CustomPoint<double> visibleSize,
    required CenterZoom centerZoom,
  }) =>
      centerZoom;
}

class VisibleCenterBoundary extends MapBoundary {
  final LatLngBounds latLngBounds;

  /// Defines bounds for the center of the visible portion of the map.
  const VisibleCenterBoundary({
    required this.latLngBounds,
  });

  @override
  CenterZoom clampCenterZoom({
    required Crs crs,
    required CustomPoint<double> visibleSize,
    required CenterZoom centerZoom,
  }) =>
      centerZoom.withCenter(
        LatLng(
          centerZoom.center.latitude.clamp(
            latLngBounds.south,
            latLngBounds.north,
          ),
          centerZoom.center.longitude.clamp(
            latLngBounds.west,
            latLngBounds.east,
          ),
        ),
      );
}

class VisibleEdgeBoundary extends MapBoundary {
  final LatLngBounds latLngBounds;

  /// Defines bounds for the visible edges of the map. Only points within these
  /// bounds will be displayed.
  VisibleEdgeBoundary({
    required this.latLngBounds,
  });

  @override
  CenterZoom? clampCenterZoom({
    required Crs crs,
    required CustomPoint<double> visibleSize,
    required CenterZoom centerZoom,
  }) {
    LatLng? newCenter;

    final testZoom = centerZoom.zoom;
    final testCenter = centerZoom.center;

    final swPixel = crs.latLngToPoint(latLngBounds.southWest, testZoom);
    final nePixel = crs.latLngToPoint(latLngBounds.northEast, testZoom);

    final centerPix = crs.latLngToPoint(testCenter, testZoom);

    final halfSizeX = visibleSize.x / 2;
    final halfSizeY = visibleSize.y / 2;

    // Try and find the edge value that the center could use to stay within
    // the maxBounds. This should be ok for panning. If we zoom, it is possible
    // there is no solution to keep all corners within the bounds. If the edges
    // are still outside the bounds, don't return anything.
    final leftOkCenter = math.min(swPixel.x, nePixel.x) + halfSizeX;
    final rightOkCenter = math.max(swPixel.x, nePixel.x) - halfSizeX;
    final topOkCenter = math.min(swPixel.y, nePixel.y) + halfSizeY;
    final botOkCenter = math.max(swPixel.y, nePixel.y) - halfSizeY;

    double? newCenterX;
    double? newCenterY;

    var wasAdjusted = false;

    if (centerPix.x < leftOkCenter) {
      wasAdjusted = true;
      newCenterX = leftOkCenter;
    } else if (centerPix.x > rightOkCenter) {
      wasAdjusted = true;
      newCenterX = rightOkCenter;
    }

    if (centerPix.y < topOkCenter) {
      wasAdjusted = true;
      newCenterY = topOkCenter;
    } else if (centerPix.y > botOkCenter) {
      wasAdjusted = true;
      newCenterY = botOkCenter;
    }

    if (!wasAdjusted) {
      return centerZoom;
    }

    final newCx = newCenterX ?? centerPix.x;
    final newCy = newCenterY ?? centerPix.y;

    // Have a final check, see if the adjusted center is within maxBounds.
    // If not, give up.
    if (newCx < leftOkCenter ||
        newCx > rightOkCenter ||
        newCy < topOkCenter ||
        newCy > botOkCenter) {
      return null;
    } else {
      newCenter = crs.pointToLatLng(CustomPoint(newCx, newCy), testZoom);
    }

    return centerZoom.withCenter(newCenter);
  }

  @override
  bool operator ==(Object other) {
    return other is VisibleEdgeBoundary && other.latLngBounds == latLngBounds;
  }

  @override
  int get hashCode => latLngBounds.hashCode;
}
