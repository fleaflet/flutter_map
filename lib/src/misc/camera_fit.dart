import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/map/camera.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';
import 'package:latlong2/latlong.dart';

/// Determines a suitable map camera given the current camera and a set of
/// constraints. See [CameraFit.bounds] if you wish to fit a given set of
/// bounds, or [CameraFit.coordinates] if you wish to fit a set of coordinates.
abstract class CameraFit {
  const CameraFit();

  /// A configuration for fitting a [MapCamera] to the given [bounds]. The
  /// [padding] may be used to leave extra space around the [bounds]. To
  /// limit the zoom of the resulting [MapCamera] use [maxZoom] (default 17.0).
  /// If [inside] is true then fit will be within the [bounds], otherwise it
  /// will contain the [bounds] (default to false, contain). Finally
  /// [forceIntegerZoomLevel] forces the resulting zoom to be rounded to the
  /// nearest whole number.
  const factory CameraFit.bounds({
    required LatLngBounds bounds,
    EdgeInsets padding,
    double maxZoom,
    bool inside,
    bool forceIntegerZoomLevel,
  }) = FitBounds;

  /// A configuration for fitting a [MapCamera] to the given [coordinates] such
  /// that all of the [coordinates] are contained in the resulting [MapCamera].
  /// The [padding] may be used to leave extra space around the [bounds]. To
  /// limit the zoom of the resulting [MapCamera] use [maxZoom] (default 17.0).
  /// If [inside] is true then fit will be within the [bounds], otherwise it
  /// will contain the [bounds] (default to false, contain). Finally
  /// [forceIntegerZoomLevel] forces the resulting zoom to be rounded to the
  /// nearest whole number.
  const factory CameraFit.coordinates({
    required List<LatLng> coordinates,
    EdgeInsets padding,
    double maxZoom,
    bool forceIntegerZoomLevel,
  }) = FitCoordinates;

  MapCamera fit(MapCamera camera);
}

/// A configuration for fitting a [MapCamera] to the given [bounds]. The
/// [padding] may be used to leave extra space around the [bounds]. To
/// limit the zoom of the resulting [MapCamera] use [maxZoom] (default 17.0).
/// If [inside] is true then fit will be within the [bounds], otherwise it
/// will contain the [bounds] (default to false, contain). Finally
/// [forceIntegerZoomLevel] forces the resulting zoom to be rounded to the
/// nearest whole number.
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

  /// Returns a new [MapCamera] which fits this classes configuration.
  @override
  MapCamera fit(MapCamera camera) {
    final paddingTL = CustomPoint<double>(padding.left, padding.top);
    final paddingBR = CustomPoint<double>(padding.right, padding.bottom);

    final paddingTotalXY = paddingTL + paddingBR;

    var newZoom = _getBoundsZoom(camera, paddingTotalXY);
    newZoom = math.min(maxZoom, newZoom);

    final paddingOffset = (paddingBR - paddingTL) / 2;
    final swPoint = camera.project(bounds.southWest, newZoom);
    final nePoint = camera.project(bounds.northEast, newZoom);

    final CustomPoint<double> projectedCenter;
    if (camera.rotation != 0.0) {
      final swPointRotated = swPoint.rotate(-camera.rotationRad);
      final nePointRotated = nePoint.rotate(-camera.rotationRad);
      final centerRotated =
          (swPointRotated + nePointRotated) / 2 + paddingOffset;

      projectedCenter = centerRotated.rotate(camera.rotationRad);
    } else {
      projectedCenter = (swPoint + nePoint) / 2 + paddingOffset;
    }

    final center = camera.unproject(projectedCenter, newZoom);
    return camera.withPosition(
      center: center,
      zoom: newZoom,
    );
  }

  double _getBoundsZoom(
    MapCamera camera,
    CustomPoint<double> pixelPadding,
  ) {
    final min = camera.minZoom ?? 0.0;
    final max = camera.maxZoom ?? double.infinity;
    final nw = bounds.northWest;
    final se = bounds.southEast;
    var size = camera.nonRotatedSize - pixelPadding;
    // Prevent negative size which results in NaN zoom value later on in the calculation
    size = CustomPoint(math.max(0, size.x), math.max(0, size.y));
    var boundsSize = Bounds(
      camera.project(se, camera.zoom),
      camera.project(nw, camera.zoom),
    ).size;
    if (camera.rotation != 0.0) {
      final cosAngle = math.cos(camera.rotationRad).abs();
      final sinAngle = math.sin(camera.rotationRad).abs();
      boundsSize = CustomPoint<double>(
        (boundsSize.x * cosAngle) + (boundsSize.y * sinAngle),
        (boundsSize.y * cosAngle) + (boundsSize.x * sinAngle),
      );
    }

    final scaleX = size.x / boundsSize.x;
    final scaleY = size.y / boundsSize.y;
    final scale = inside ? math.max(scaleX, scaleY) : math.min(scaleX, scaleY);

    var boundsZoom = camera.getScaleZoom(scale);

    if (forceIntegerZoomLevel) {
      boundsZoom =
          inside ? boundsZoom.ceilToDouble() : boundsZoom.floorToDouble();
    }

    return math.max(min, math.min(max, boundsZoom));
  }
}

/// A configuration for fitting a [MapCamera] to the given [coordinates] such
/// that all of the [coordinates] are contained in the resulting [MapCamera].
/// The [padding] may be used to leave extra space around the [bounds]. To
/// limit the zoom of the resulting [MapCamera] use [maxZoom] (default 17.0).
/// If [inside] is true then fit will be within the [bounds], otherwise it
/// will contain the [bounds] (default to false, contain). Finally
/// [forceIntegerZoomLevel] forces the resulting zoom to be rounded to the
/// nearest whole number.
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

  /// Returns a new [MapCamera] which fits this classes configuration.
  @override
  MapCamera fit(MapCamera camera) {
    final paddingTL = CustomPoint<double>(padding.left, padding.top);
    final paddingBR = CustomPoint<double>(padding.right, padding.bottom);

    final paddingTotalXY = paddingTL + paddingBR;

    var newZoom = _getCoordinatesZoom(camera, paddingTotalXY);
    newZoom = math.min(maxZoom, newZoom);

    final projectedPoints = [
      for (final coord in coordinates) camera.project(coord, newZoom)
    ];

    final rotatedPoints =
        projectedPoints.map((point) => point.rotate(-camera.rotationRad));

    final rotatedBounds = Bounds.containing(rotatedPoints);

    // Apply padding
    final paddingOffset = (paddingBR - paddingTL) / 2;
    final rotatedNewCenter = rotatedBounds.center + paddingOffset;

    // Undo the rotation
    final unrotatedNewCenter = rotatedNewCenter.rotate(camera.rotationRad);

    final newCenter = camera.unproject(unrotatedNewCenter, newZoom);

    return camera.withPosition(
      center: newCenter,
      zoom: newZoom,
    );
  }

  double _getCoordinatesZoom(
    MapCamera camera,
    CustomPoint<double> pixelPadding,
  ) {
    final min = camera.minZoom ?? 0.0;
    final max = camera.maxZoom ?? double.infinity;
    var size = camera.nonRotatedSize - pixelPadding;
    // Prevent negative size which results in NaN zoom value later on in the calculation
    size = CustomPoint(math.max(0, size.x), math.max(0, size.y));

    final projectedPoints = [
      for (final coord in coordinates) camera.project(coord)
    ];

    final rotatedPoints =
        projectedPoints.map((point) => point.rotate(-camera.rotationRad));
    final rotatedBounds = Bounds.containing(rotatedPoints);

    final boundsSize = rotatedBounds.size;

    final scaleX = size.x / boundsSize.x;
    final scaleY = size.y / boundsSize.y;
    final scale = math.min(scaleX, scaleY);

    var newZoom = camera.getScaleZoom(scale);
    if (forceIntegerZoomLevel) {
      newZoom = newZoom.floorToDouble();
    }

    return math.max(min, math.min(max, newZoom));
  }
}
