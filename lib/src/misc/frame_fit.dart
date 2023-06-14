import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';

abstract class FrameFit {
  const FrameFit();

  const factory FrameFit.bounds({
    required LatLngBounds bounds,
    EdgeInsets padding,
    double maxZoom,
    bool inside,
    bool forceIntegerZoomLevel,
  }) = FitBounds;

  FlutterMapState fit(FlutterMapState mapState);
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
  FlutterMapState fit(FlutterMapState mapState) {
    final paddingTL = CustomPoint<double>(padding.left, padding.top);
    final paddingBR = CustomPoint<double>(padding.right, padding.bottom);

    final paddingTotalXY = paddingTL + paddingBR;

    var newZoom = getBoundsZoom(mapState, bounds, paddingTotalXY);
    newZoom = math.min(maxZoom, newZoom);

    final paddingOffset = (paddingBR - paddingTL) / 2;
    final swPoint = mapState.project(bounds.southWest, newZoom);
    final nePoint = mapState.project(bounds.northEast, newZoom);

    final CustomPoint<double> projectedCenter;
    if (mapState.rotation != 0.0) {
      final swPointRotated = swPoint.rotate(-mapState.rotationRad);
      final nePointRotated = nePoint.rotate(-mapState.rotationRad);
      final centerRotated =
          (swPointRotated + nePointRotated) / 2 + paddingOffset;

      projectedCenter = centerRotated.rotate(mapState.rotationRad);
    } else {
      projectedCenter = (swPoint + nePoint) / 2 + paddingOffset;
    }

    final center = mapState.unproject(projectedCenter, newZoom);
    return mapState.withPosition(
      center: center,
      zoom: newZoom,
    );
  }

  double getBoundsZoom(
    FlutterMapState mapState,
    LatLngBounds bounds,
    CustomPoint<double> pixelPadding,
  ) {
    final min = mapState.minZoom ?? 0.0;
    final max = mapState.maxZoom ?? double.infinity;
    final nw = bounds.northWest;
    final se = bounds.southEast;
    var size = mapState.nonRotatedSize - pixelPadding;
    // Prevent negative size which results in NaN zoom value later on in the calculation
    size = CustomPoint(math.max(0, size.x), math.max(0, size.y));
    var boundsSize = Bounds(
      mapState.project(se, mapState.zoom),
      mapState.project(nw, mapState.zoom),
    ).size;
    if (mapState.rotation != 0.0) {
      final cosAngle = math.cos(mapState.rotationRad).abs();
      final sinAngle = math.sin(mapState.rotationRad).abs();
      boundsSize = CustomPoint<double>(
        (boundsSize.x * cosAngle) + (boundsSize.y * sinAngle),
        (boundsSize.y * cosAngle) + (boundsSize.x * sinAngle),
      );
    }

    final scaleX = size.x / boundsSize.x;
    final scaleY = size.y / boundsSize.y;
    final scale = inside ? math.max(scaleX, scaleY) : math.min(scaleX, scaleY);

    var boundsZoom = mapState.getScaleZoom(scale, mapState.zoom);

    if (forceIntegerZoomLevel) {
      boundsZoom =
          inside ? boundsZoom.ceilToDouble() : boundsZoom.floorToDouble();
    }

    return math.max(min, math.min(max, boundsZoom));
  }
}
