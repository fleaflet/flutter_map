import 'dart:math' as math hide Point;
import 'dart:math' show Point;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Describes a position for a [MapCamera]
///
/// Constraints are handled by [CameraConstraint].
@immutable
abstract class CameraFit {
  /// Describes a position for a [MapCamera]
  ///
  /// Constraints are handled by [CameraConstraint].
  const CameraFit();

  /// Fits the [bounds] inside the camera
  ///
  /// For information about available options, see the documentation on the
  /// appropriate properties.
  const factory CameraFit.bounds({
    required LatLngBounds bounds,
    EdgeInsets padding,
    double? maxZoom,
    double minZoom,
    bool forceIntegerZoomLevel,
  }) = FitBounds._;

  /// Fits the camera inside the [bounds]
  ///
  /// For information about available options, see the documentation on the
  /// appropriate properties.
  const factory CameraFit.insideBounds({
    required LatLngBounds bounds,
    EdgeInsets padding,
    double? maxZoom,
    double minZoom,
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
  /// `inside` is not supported due to lack of implementation.
  const factory CameraFit.coordinates({
    required List<LatLng> coordinates,
    EdgeInsets padding,
    double? maxZoom,
    double minZoom,
    bool forceIntegerZoomLevel,
  }) = FitCoordinates._;

  /// Create a new fitted camera based off the current [camera]
  MapCamera fit(MapCamera camera);
}

/// The [CameraFit] should fit inside a given [LatLngBounds].
@immutable
class FitBounds extends CameraFit {
  /// The bounds which the camera should contain once it is fitted.
  final LatLngBounds bounds;

  /// Adds a constant/pixel-based padding to the normal fit.
  ///
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsets padding;

  /// The inclusive upper zoom limit used for the resulting fit.
  ///
  /// If the zoom level calculated for the fit exceeds the [maxZoom] value,
  /// [maxZoom] will be used instead.
  ///
  /// Defaults to null.
  final double? maxZoom;

  /// The inclusive lower zoom limit used for the resulting fit.
  ///
  /// If the zoom level calculated for the fit undercuts the [minZoom] value,
  /// [minZoom] will be used instead.
  final double minZoom;

  /// Whether the zoom level of the resulting fit should be rounded to the
  /// nearest integer level.
  ///
  /// Defaults to `false`.
  final bool forceIntegerZoomLevel;

  const FitBounds._({
    required this.bounds,
    this.padding = EdgeInsets.zero,
    this.maxZoom,
    this.minZoom = 0,
    this.forceIntegerZoomLevel = false,
  });

  /// Returns a new [MapCamera] which fits this classes configuration.
  @override
  MapCamera fit(MapCamera camera) {
    final paddingTL = Point<double>(padding.left, padding.top);
    final paddingBR = Point<double>(padding.right, padding.bottom);

    final paddingTotalXY = paddingTL + paddingBR;

    var newZoom = _getBoundsZoom(camera, paddingTotalXY);
    if (maxZoom != null) newZoom = math.min(maxZoom!, newZoom);

    final paddingOffset = (paddingBR - paddingTL) / 2;
    final swPoint = camera.project(bounds.southWest, newZoom);
    final nePoint = camera.project(bounds.northEast, newZoom);

    final Point<double> projectedCenter;
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
    Point<double> pixelPadding,
  ) {
    final nw = bounds.northWest;
    final se = bounds.southEast;
    var size = camera.nonRotatedSize - pixelPadding;
    // Prevent negative size which results in NaN zoom value later on in the calculation
    size = Point(math.max(0, size.x), math.max(0, size.y));
    var boundsSize = Bounds(
      camera.project(se, camera.zoom),
      camera.project(nw, camera.zoom),
    ).size;
    if (camera.rotation != 0.0) {
      final cosAngle = math.cos(camera.rotationRad).abs();
      final sinAngle = math.sin(camera.rotationRad).abs();
      boundsSize = Point<double>(
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

    final min = math.max(
      camera.minZoom ?? 0,
      minZoom,
    );
    final max = math.min(
      camera.maxZoom ?? double.infinity,
      maxZoom ?? double.infinity,
    );
    return boundsZoom.clamp(min, max);
  }
}

/// A [CameraFit] that should get be within given [LatLngBounds].
@immutable
class FitInsideBounds extends CameraFit {
  /// The bounds which the camera should fit inside once it is fitted.
  final LatLngBounds bounds;

  /// Adds a constant/pixel-based padding to the normal fit.
  ///
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsets padding;

  /// The inclusive upper zoom limit used for the resulting fit.
  ///
  /// If the zoom level calculated for the fit exceeds the [maxZoom] value,
  /// [maxZoom] will be used instead.
  ///
  /// Defaults to null.
  final double? maxZoom;

  /// The inclusive lower zoom limit used for the resulting fit.
  ///
  /// If the zoom level calculated for the fit undercuts the [minZoom] value,
  /// [minZoom] will be used instead.
  final double minZoom;

  /// Whether the zoom level of the resulting fit should be rounded to the
  /// nearest integer level.
  ///
  /// Defaults to `false`.
  final bool forceIntegerZoomLevel;

  const FitInsideBounds._({
    required this.bounds,
    this.padding = EdgeInsets.zero,
    this.maxZoom,
    this.minZoom = 0,
    this.forceIntegerZoomLevel = false,
  });

  @override
  MapCamera fit(MapCamera camera) {
    final paddingTL = Point<double>(padding.left, padding.top);
    final paddingBR = Point<double>(padding.right, padding.bottom);
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

    final min = math.max(
      camera.minZoom ?? 0,
      minZoom,
    );
    final max = math.min(
      camera.maxZoom ?? double.infinity,
      maxZoom ?? double.infinity,
    );
    newZoom = newZoom.clamp(min, max);

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
    required Point<double> paddingOffset,
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

/// Use this [CameraFit] if the [MapCamera] should fit a list of [LatLng]
/// coordinates.
@immutable
class FitCoordinates extends CameraFit {
  /// The coordinates which the camera should contain once it is fitted.
  final List<LatLng> coordinates;

  /// Adds a constant/pixel-based padding to the normal fit.
  ///
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsets padding;

  /// The inclusive upper zoom limit used for the resulting fit.
  ///
  /// If the zoom level calculated for the fit exceeds the [maxZoom] value,
  /// [maxZoom] will be used instead.
  ///
  /// Defaults to null.
  final double? maxZoom;

  /// The inclusive lower zoom limit used for the resulting fit.
  ///
  /// If the zoom level calculated for the fit undercuts the [minZoom] value,
  /// [minZoom] will be used instead.
  final double minZoom;

  /// Whether the zoom level of the resulting fit should be rounded to the
  /// nearest integer level.
  ///
  /// Defaults to `false`.
  final bool forceIntegerZoomLevel;

  const FitCoordinates._({
    required this.coordinates,
    this.padding = EdgeInsets.zero,
    this.maxZoom = double.infinity,
    this.minZoom = 0,
    this.forceIntegerZoomLevel = false,
  });

  /// Returns a new [MapCamera] which fits this classes configuration.
  @override
  MapCamera fit(MapCamera camera) {
    final paddingTL = Point<double>(padding.left, padding.top);
    final paddingBR = Point<double>(padding.right, padding.bottom);

    final paddingTotalXY = paddingTL + paddingBR;

    var newZoom = _getCoordinatesZoom(camera, paddingTotalXY);
    if (maxZoom != null) newZoom = math.min(maxZoom!, newZoom);

    final projectedPoints =
        coordinates.map((coord) => camera.project(coord, newZoom));

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
    Point<double> pixelPadding,
  ) {
    var size = camera.nonRotatedSize - pixelPadding;
    // Prevent negative size which results in NaN zoom value later on in the calculation
    size = Point(math.max(0, size.x), math.max(0, size.y));

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

    final min = math.max(
      camera.minZoom ?? 0,
      minZoom,
    );
    final max = math.min(
      camera.maxZoom ?? double.infinity,
      maxZoom ?? double.infinity,
    );
    return newZoom.clamp(min, max);
  }
}
