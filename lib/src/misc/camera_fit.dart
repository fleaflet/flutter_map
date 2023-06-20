import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/map/camera.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';
import 'package:latlong2/latlong.dart';

abstract class CameraFit {
  const CameraFit();

  const factory CameraFit.bounds({
    required LatLngBounds bounds,
    EdgeInsets padding,
    double maxZoom,
    bool inside,
    bool forceIntegerZoomLevel,
  }) = FitBounds;

  const factory CameraFit.coordinates({
    required List<LatLng> coordinates,
    EdgeInsets padding,
    double maxZoom,
    bool forceIntegerZoomLevel,
  }) = FitCoordinates;

  MapCamera fit(MapCamera mapCamera);
}

class FitBounds extends CameraFit {
  final LatLngBounds bounds;
  final EdgeInsets padding;
  final double maxZoom;
  final bool inside;

  /// By default calculations will return fractional zoom levels.
  /// If this parameter is set to [true] fractional zoom levels will be round
  /// to the next suitable integer.
  final bool forceIntegerZoomLevel;

  const FitBounds({
    required this.bounds,
    this.padding = EdgeInsets.zero,
    this.maxZoom = 17.0,
    this.inside = false,
    this.forceIntegerZoomLevel = false,
  });

  @override
  MapCamera fit(MapCamera mapCamera) {
    final paddingTL = CustomPoint<double>(padding.left, padding.top);
    final paddingBR = CustomPoint<double>(padding.right, padding.bottom);

    final paddingTotalXY = paddingTL + paddingBR;

    var newZoom = getBoundsZoom(mapCamera, paddingTotalXY);
    newZoom = math.min(maxZoom, newZoom);

    final paddingOffset = (paddingBR - paddingTL) / 2;
    final swPoint = mapCamera.project(bounds.southWest, newZoom);
    final nePoint = mapCamera.project(bounds.northEast, newZoom);

    final CustomPoint<double> projectedCenter;
    if (mapCamera.rotation != 0.0) {
      final swPointRotated = swPoint.rotate(-mapCamera.rotationRad);
      final nePointRotated = nePoint.rotate(-mapCamera.rotationRad);
      final centerRotated =
          (swPointRotated + nePointRotated) / 2 + paddingOffset;

      projectedCenter = centerRotated.rotate(mapCamera.rotationRad);
    } else {
      projectedCenter = (swPoint + nePoint) / 2 + paddingOffset;
    }

    final center = mapCamera.unproject(projectedCenter, newZoom);
    return mapCamera.withPosition(
      center: center,
      zoom: newZoom,
    );
  }

  double getBoundsZoom(
    MapCamera mapCamera,
    CustomPoint<double> pixelPadding,
  ) {
    final min = mapCamera.minZoom ?? 0.0;
    final max = mapCamera.maxZoom ?? double.infinity;
    final nw = bounds.northWest;
    final se = bounds.southEast;
    var size = mapCamera.nonRotatedSize - pixelPadding;
    // Prevent negative size which results in NaN zoom value later on in the calculation
    size = CustomPoint(math.max(0, size.x), math.max(0, size.y));
    var boundsSize = Bounds(
      mapCamera.project(se, mapCamera.zoom),
      mapCamera.project(nw, mapCamera.zoom),
    ).size;
    if (mapCamera.rotation != 0.0) {
      final cosAngle = math.cos(mapCamera.rotationRad).abs();
      final sinAngle = math.sin(mapCamera.rotationRad).abs();
      boundsSize = CustomPoint<double>(
        (boundsSize.x * cosAngle) + (boundsSize.y * sinAngle),
        (boundsSize.y * cosAngle) + (boundsSize.x * sinAngle),
      );
    }

    final scaleX = size.x / boundsSize.x;
    final scaleY = size.y / boundsSize.y;
    final scale = inside ? math.max(scaleX, scaleY) : math.min(scaleX, scaleY);

    var boundsZoom = mapCamera.getScaleZoom(scale, mapCamera.zoom);

    if (forceIntegerZoomLevel) {
      boundsZoom =
          inside ? boundsZoom.ceilToDouble() : boundsZoom.floorToDouble();
    }

    return math.max(min, math.min(max, boundsZoom));
  }
}

class FitCoordinates extends CameraFit {
  final List<LatLng> coordinates;
  final EdgeInsets padding;
  final double maxZoom;

  /// By default calculations will return fractional zoom levels.
  /// If this parameter is set to [true] fractional zoom levels will be round
  /// to the next suitable integer.
  final bool forceIntegerZoomLevel;

  const FitCoordinates({
    required this.coordinates,
    this.padding = EdgeInsets.zero,
    this.maxZoom = 17.0,
    this.forceIntegerZoomLevel = false,
  });

  @override
  MapCamera fit(MapCamera mapCamera) {
    final paddingTL = CustomPoint<double>(padding.left, padding.top);
    final paddingBR = CustomPoint<double>(padding.right, padding.bottom);

    final paddingTotalXY = paddingTL + paddingBR;

    var newZoom = getCoordinatesZoom(mapCamera, paddingTotalXY);
    newZoom = math.min(maxZoom, newZoom);

    final projectedPoints = [
      for (final coord in coordinates) mapCamera.project(coord, newZoom)
    ];

    final rotatedPoints =
        projectedPoints.map((point) => point.rotate(-mapCamera.rotationRad));

    final rotatedBounds = Bounds.containing(rotatedPoints);

    // Apply padding
    final paddingOffset = (paddingBR - paddingTL) / 2;
    final rotatedNewCenter = rotatedBounds.center + paddingOffset;

    // Undo the rotation
    final unrotatedNewCenter = rotatedNewCenter.rotate(mapCamera.rotationRad);

    final newCenter = mapCamera.unproject(unrotatedNewCenter, newZoom);

    return mapCamera.withPosition(
      center: newCenter,
      zoom: newZoom,
    );
  }

  double getCoordinatesZoom(
    MapCamera mapCamera,
    CustomPoint<double> pixelPadding,
  ) {
    final min = mapCamera.minZoom ?? 0.0;
    final max = mapCamera.maxZoom ?? double.infinity;
    var size = mapCamera.nonRotatedSize - pixelPadding;
    // Prevent negative size which results in NaN zoom value later on in the calculation
    size = CustomPoint(math.max(0, size.x), math.max(0, size.y));

    final projectedPoints = [
      for (final coord in coordinates) mapCamera.project(coord)
    ];

    final rotatedPoints =
        projectedPoints.map((point) => point.rotate(-mapCamera.rotationRad));
    final rotatedBounds = Bounds.containing(rotatedPoints);

    final boundsSize = rotatedBounds.size;

    final scaleX = size.x / boundsSize.x;
    final scaleY = size.y / boundsSize.y;
    final scale = math.min(scaleX, scaleY);

    var newZoom = mapCamera.getScaleZoom(scale, mapCamera.zoom);
    if (forceIntegerZoomLevel) {
      newZoom = newZoom.floorToDouble();
    }

    return math.max(min, math.min(max, newZoom));
  }
}
