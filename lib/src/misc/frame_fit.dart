import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/map/flutter_map_frame.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';
import 'package:latlong2/latlong.dart';

abstract class FrameFit {
  const FrameFit();

  const factory FrameFit.bounds({
    required LatLngBounds bounds,
    EdgeInsets padding,
    double maxZoom,
    bool inside,
    bool forceIntegerZoomLevel,
  }) = FitBounds;

  const factory FrameFit.coordinates({
    required List<LatLng> coordinates,
    EdgeInsets padding,
    double maxZoom,
    bool inside,
    bool forceIntegerZoomLevel,
  }) = FitCoordinates;

  FlutterMapFrame fit(FlutterMapFrame mapFrame);
}

class FitBounds extends FrameFit {
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
  FlutterMapFrame fit(FlutterMapFrame mapFrame) {
    final paddingTL = CustomPoint<double>(padding.left, padding.top);
    final paddingBR = CustomPoint<double>(padding.right, padding.bottom);

    final paddingTotalXY = paddingTL + paddingBR;

    var newZoom = getBoundsZoom(mapFrame, paddingTotalXY);
    newZoom = math.min(maxZoom, newZoom);

    final paddingOffset = (paddingBR - paddingTL) / 2;
    final swPoint = mapFrame.project(bounds.southWest, newZoom);
    final nePoint = mapFrame.project(bounds.northEast, newZoom);

    final CustomPoint<double> projectedCenter;
    if (mapFrame.rotation != 0.0) {
      final swPointRotated = swPoint.rotate(-mapFrame.rotationRad);
      final nePointRotated = nePoint.rotate(-mapFrame.rotationRad);
      final centerRotated =
          (swPointRotated + nePointRotated) / 2 + paddingOffset;

      projectedCenter = centerRotated.rotate(mapFrame.rotationRad);
    } else {
      projectedCenter = (swPoint + nePoint) / 2 + paddingOffset;
    }

    final center = mapFrame.unproject(projectedCenter, newZoom);
    return mapFrame.withPosition(
      center: center,
      zoom: newZoom,
    );
  }

  double getBoundsZoom(
    FlutterMapFrame mapFrame,
    CustomPoint<double> pixelPadding,
  ) {
    final min = mapFrame.minZoom ?? 0.0;
    final max = mapFrame.maxZoom ?? double.infinity;
    final nw = bounds.northWest;
    final se = bounds.southEast;
    var size = mapFrame.nonRotatedSize - pixelPadding;
    // Prevent negative size which results in NaN zoom value later on in the calculation
    size = CustomPoint(math.max(0, size.x), math.max(0, size.y));
    var boundsSize = Bounds(
      mapFrame.project(se, mapFrame.zoom),
      mapFrame.project(nw, mapFrame.zoom),
    ).size;
    if (mapFrame.rotation != 0.0) {
      final cosAngle = math.cos(mapFrame.rotationRad).abs();
      final sinAngle = math.sin(mapFrame.rotationRad).abs();
      boundsSize = CustomPoint<double>(
        (boundsSize.x * cosAngle) + (boundsSize.y * sinAngle),
        (boundsSize.y * cosAngle) + (boundsSize.x * sinAngle),
      );
    }

    final scaleX = size.x / boundsSize.x;
    final scaleY = size.y / boundsSize.y;
    final scale = inside ? math.max(scaleX, scaleY) : math.min(scaleX, scaleY);

    var boundsZoom = mapFrame.getScaleZoom(scale, mapFrame.zoom);

    if (forceIntegerZoomLevel) {
      boundsZoom =
          inside ? boundsZoom.ceilToDouble() : boundsZoom.floorToDouble();
    }

    return math.max(min, math.min(max, boundsZoom));
  }
}

class FitCoordinates extends FrameFit {
  final List<LatLng> coordinates;
  final EdgeInsets padding;
  final double maxZoom;
  final bool inside;

  /// By default calculations will return fractional zoom levels.
  /// If this parameter is set to [true] fractional zoom levels will be round
  /// to the next suitable integer.
  final bool forceIntegerZoomLevel;

  const FitCoordinates({
    required this.coordinates,
    this.padding = EdgeInsets.zero,
    this.maxZoom = 17.0,
    this.inside = false,
    this.forceIntegerZoomLevel = false,
  });

  @override
  FlutterMapFrame fit(FlutterMapFrame mapFrame) {
    final paddingTL = CustomPoint<double>(padding.left, padding.top);
    final paddingBR = CustomPoint<double>(padding.right, padding.bottom);

    final paddingTotalXY = paddingTL + paddingBR;

    var newZoom = getCoordinatesZoom(mapFrame, paddingTotalXY);
    newZoom = math.min(maxZoom, newZoom);

    final projectedPoints = [
      for (final coord in coordinates) mapFrame.project(coord, newZoom)
    ];

    final rotatedPoints =
        projectedPoints.map((point) => point.rotate(-mapFrame.rotationRad));

    final rotatedBounds = Bounds.containing(rotatedPoints);

    // Apply padding
    final paddingOffset = (paddingBR - paddingTL) / 2;
    final rotatedNewCenter = rotatedBounds.center + paddingOffset;

    // Undo the rotation
    final unrotatedNewCenter = rotatedNewCenter.rotate(mapFrame.rotationRad);

    final newCenter = mapFrame.unproject(unrotatedNewCenter, newZoom);

    return mapFrame.withPosition(
      center: newCenter,
      zoom: newZoom,
    );
  }

  double getCoordinatesZoom(
    FlutterMapFrame mapFrame,
    CustomPoint<double> pixelPadding,
  ) {
    final min = mapFrame.minZoom ?? 0.0;
    final max = mapFrame.maxZoom ?? double.infinity;
    var size = mapFrame.nonRotatedSize - pixelPadding;
    // Prevent negative size which results in NaN zoom value later on in the calculation
    size = CustomPoint(math.max(0, size.x), math.max(0, size.y));

    final projectedPoints = [
      for (final coord in coordinates) mapFrame.project(coord)
    ];

    final rotatedPoints =
        projectedPoints.map((point) => point.rotate(-mapFrame.rotationRad));
    final rotatedBounds = Bounds.containing(rotatedPoints);

    final boundsSize = rotatedBounds.size;

    final scaleX = size.x / boundsSize.x;
    final scaleY = size.y / boundsSize.y;
    final scale = inside ? math.max(scaleX, scaleY) : math.min(scaleX, scaleY);

    var newZoom = mapFrame.getScaleZoom(scale, mapFrame.zoom);
    if (forceIntegerZoomLevel) {
      newZoom = inside ? newZoom.ceilToDouble() : newZoom.floorToDouble();
    }

    return math.max(min, math.min(max, newZoom));
  }
}
