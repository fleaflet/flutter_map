import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/map/camera/camera_constraint.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';
import 'package:latlong2/latlong.dart';

/// Describes a position for a [MapCamera]
///
/// Constraints are handled by [CameraConstraint].
abstract class CameraFit {
  /// Describes a position for a [MapCamera]
  ///
  /// Constraints are handled by [CameraConstraint].
  const CameraFit({
    this.padding = EdgeInsets.zero,
    this.maxZoom = 18,
    this.forceIntegerZoomLevel = false,
  });

  /// Adds a constant/pixel-based padding to the normal fit
  ///
  /// Defaults to [EdgeInsets.zero]
  final EdgeInsets padding;

  /// Limits the maximum zoom level of the resulting fit
  ///
  /// Defaults to zoom level 18.
  final double maxZoom;

  /// Whether the zoom level of the resulting fit should be rounded to the
  /// nearest integer level
  ///
  /// Defaults to `false`.
  final bool forceIntegerZoomLevel;

  /// Fits the [bounds] inside the camera
  ///
  /// For information about available options, see the documentation on the
  /// appropriate properties.
  const factory CameraFit.bounds({
    required LatLngBounds bounds,
    EdgeInsets padding,
    double maxZoom,
    bool forceIntegerZoomLevel,
  }) = FitBounds._;

  /// Fits the camera inside the [bounds]
  ///
  /// For information about available options, see the documentation on the
  /// appropriate properties.
  const factory CameraFit.insideBounds({
    required LatLngBounds bounds,
    EdgeInsets padding,
    double maxZoom,
    bool forceIntegerZoomLevel,
  }) = FitInsideBounds._;

  /// Fits the camera to the [coordinates], as closely as possible
  ///
  /// For information about available options, see the documentation on the
  /// appropriate properties.
  ///
  /// Allows for more fine grained boundaries when the camera is rotated. See
  /// https://github.com/fleaflet/flutter_map/pull/1549 for more information.
  ///
  /// [inside] is not supported due to lack of implementation.
  const factory CameraFit.coordinates({
    required List<LatLng> coordinates,
    EdgeInsets padding,
    double maxZoom,
    bool forceIntegerZoomLevel,
  }) = FitCoordinates._;

  /// Create a new fitted camera based off the current [camera]
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

  const FitBounds._({
    required this.bounds,
    super.padding,
    super.maxZoom,
    super.forceIntegerZoomLevel,
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
    final scale = math.min(scaleX, scaleY);

    var boundsZoom = camera.getScaleZoom(scale);

    if (forceIntegerZoomLevel) {
      boundsZoom = boundsZoom.floorToDouble();
    }

    return math.max(min, math.min(max, boundsZoom));
  }
}

class FitInsideBounds extends CameraFit {
  final LatLngBounds bounds;

  const FitInsideBounds._({
    required this.bounds,
    super.padding,
    super.maxZoom,
    super.forceIntegerZoomLevel,
  });

  @override
  MapCamera fit(MapCamera camera) {
    final paddingTL = CustomPoint<double>(padding.left, padding.top);
    final paddingBR = CustomPoint<double>(padding.right, padding.bottom);
    final paddingTotalXY = paddingTL + paddingBR;
    final paddingOffset = (paddingBR - paddingTL) / 2;

    final cameraSize = camera.nonRotatedSize - paddingTotalXY;

    final projectedBoundsSize = Bounds(
      camera.project(bounds.southEast, camera.zoom),
      camera.project(bounds.northWest, camera.zoom),
    ).size;

    final scale = _rectInRotRectScale(
      angleRad: camera.rotationRad,
      smallRectHalfWidth: cameraSize.x / 2.0,
      smallRectHalfHeight: cameraSize.y / 2.0,
      bigRectHalfWidth: projectedBoundsSize.x / 2.0,
      bigRectHalfHeight: projectedBoundsSize.y / 2.0,
    );

    var newZoom = camera.getScaleZoom(1.0 / scale);

    if (forceIntegerZoomLevel) {
      newZoom = newZoom.ceilToDouble();
    }

    newZoom = math.max(
      camera.minZoom ?? 0.0,
      math.min(
        math.min(maxZoom, camera.maxZoom ?? double.infinity),
        newZoom,
      ),
    );

    final newCenter = _getCenter(
      camera,
      newZoom: newZoom,
      paddingOffset: paddingOffset,
    );

    return camera.withPosition(
      center: newCenter,
      zoom: newZoom,
    );
  }

  LatLng _getCenter(
    MapCamera camera, {
    required double newZoom,
    required CustomPoint<double> paddingOffset,
  }) {
    if (camera.rotation == 0.0) {
      final swPoint = camera.project(bounds.southWest, newZoom);
      final nePoint = camera.project(bounds.northEast, newZoom);
      final projectedCenter = (swPoint + nePoint) / 2 + paddingOffset;
      final newCenter = camera.unproject(projectedCenter, newZoom);

      return newCenter;
    }

    // Handle rotation
    final projectedCenter = camera.project(bounds.center, newZoom);
    final rotatedCenter = projectedCenter.rotate(-camera.rotationRad);
    final adjustedCenter = rotatedCenter + paddingOffset;
    final derotatedAdjustedCenter = adjustedCenter.rotate(camera.rotationRad);
    final newCenter = camera.unproject(derotatedAdjustedCenter, newZoom);

    return newCenter;
  }

  static double _normalize(double value, double start, double end) {
    final width = end - start;
    final offsetValue = value - start;

    return (offsetValue - (offsetValue / width).floorToDouble() * width) +
        start;
  }

  /// Given two rectangles with their centers at the origin and an angle by
  /// which the big rectangle is rotated, calculates the coefficient that would
  /// be needed to scale the small rectangle such that it fits perfectly in the
  /// larger rectangle while maintaining its aspect ratio.
  ///
  /// This algorithm has been adapted from https://stackoverflow.com/a/75907251
  static double _rectInRotRectScale({
    required double angleRad,
    required double smallRectHalfWidth,
    required double smallRectHalfHeight,
    required double bigRectHalfWidth,
    required double bigRectHalfHeight,
  }) {
    angleRad = _normalize(angleRad, 0, 2.0 * math.pi);
    var kmin = double.infinity;
    final quadrant = (2.0 * angleRad / math.pi).floor();
    if (quadrant.isOdd) {
      final px = bigRectHalfWidth * math.cos(angleRad) +
          bigRectHalfHeight * math.sin(angleRad);
      final py = bigRectHalfWidth * math.sin(angleRad) -
          bigRectHalfHeight * math.cos(angleRad);
      final dx = -math.cos(angleRad);
      final dy = -math.sin(angleRad);

      if (smallRectHalfWidth * dy - smallRectHalfHeight * dx != 0) {
        var k = (px * dy - py * dx) /
            (smallRectHalfWidth * dy - smallRectHalfHeight * dx);
        if (quadrant >= 2) {
          k = -k;
        }

        if (k > 0) {
          kmin = math.min(kmin, k);
        }
      }

      if (-smallRectHalfWidth * dx + smallRectHalfHeight * dy != 0) {
        var k = (px * dx + py * dy) /
            (-smallRectHalfWidth * dx + smallRectHalfHeight * dy);
        if (quadrant >= 2) {
          k = -k;
        }

        if (k > 0) {
          kmin = math.min(kmin, k);
        }
      }

      return kmin;
    } else {
      final px = bigRectHalfWidth * math.cos(angleRad) -
          bigRectHalfHeight * math.sin(angleRad);
      final py = bigRectHalfWidth * math.sin(angleRad) +
          bigRectHalfHeight * math.cos(angleRad);
      final dx = math.sin(angleRad);
      final dy = -math.cos(angleRad);
      if (smallRectHalfWidth * dy - smallRectHalfHeight * dx != 0) {
        var k = (px * dy - py * dx) /
            (smallRectHalfWidth * dy - smallRectHalfHeight * dx);
        if (quadrant >= 2) {
          k = -k;
        }

        if (k > 0) {
          kmin = math.min(kmin, k);
        }
      }

      if (-smallRectHalfWidth * dx + smallRectHalfHeight * dy != 0) {
        var k = (px * dx + py * dy) /
            (-smallRectHalfWidth * dx + smallRectHalfHeight * dy);
        if (quadrant >= 2) {
          k = -k;
        }

        if (k > 0) {
          kmin = math.min(kmin, k);
        }
      }

      return kmin;
    }
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

  const FitCoordinates._({
    required this.coordinates,
    super.padding,
    super.maxZoom,
    super.forceIntegerZoomLevel,
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
