import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/misc/extensions.dart';
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
    if (camera.pitch == 0) return _fitUnpitched(camera);
    return _fitPitched(
      camera,
      [
        bounds.northWest,
        bounds.northEast,
        bounds.southEast,
        bounds.southWest,
      ],
      padding,
      start: _fitUnpitched(camera.withPitch(0)).withPitch(camera.pitch),
      limitZoom: (zoom) => _limitZoom(
        camera,
        zoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
        forceIntegerZoomLevel: forceIntegerZoomLevel,
      ),
    );
  }

  MapCamera _fitUnpitched(MapCamera camera) {
    final paddingTL = Offset(padding.left, padding.top);
    final paddingBR = Offset(padding.right, padding.bottom);

    final paddingTotalXY = paddingTL + paddingBR;

    var newZoom = _getBoundsZoom(camera, paddingTotalXY);
    if (maxZoom != null) newZoom = math.min(maxZoom!, newZoom);

    final paddingOffset = (paddingBR - paddingTL) / 2;
    final swPoint = camera.projectAtZoom(bounds.southWest, newZoom);
    final nePoint = camera.projectAtZoom(bounds.northEast, newZoom);

    final Offset projectedCenter;
    if (camera.rotation != 0.0) {
      final swPointRotated = swPoint.rotate(-camera.rotationRad);
      final nePointRotated = nePoint.rotate(-camera.rotationRad);
      final centerRotated =
          (swPointRotated + nePointRotated) / 2 + paddingOffset;

      projectedCenter = centerRotated.rotate(camera.rotationRad);
    } else {
      projectedCenter = (swPoint + nePoint) / 2 + paddingOffset;
    }

    final center = camera.unprojectAtZoom(projectedCenter, newZoom);
    return camera.withPosition(
      center: center,
      zoom: newZoom,
    );
  }

  double _getBoundsZoom(
    MapCamera camera,
    Offset pixelPadding,
  ) {
    final nw = bounds.northWest;
    final se = bounds.southEast;
    var size = camera.nonRotatedSize - pixelPadding as Size;
    // Prevent negative size which results in NaN zoom value later on in the calculation

    size = Size(math.max(0, size.width), math.max(0, size.height));
    var boundsSize = Rect.fromPoints(
      camera.projectAtZoom(se, camera.zoom),
      camera.projectAtZoom(nw, camera.zoom),
    ).size;
    if (camera.rotation != 0.0) {
      final cosAngle = math.cos(camera.rotationRad).abs();
      final sinAngle = math.sin(camera.rotationRad).abs();
      boundsSize = Size(
        (boundsSize.width * cosAngle) + (boundsSize.height * sinAngle),
        (boundsSize.height * cosAngle) + (boundsSize.width * sinAngle),
      );
    }

    final scale = math.min(
        size.width / boundsSize.width, size.height / boundsSize.height);

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
  MapCamera fit(MapCamera camera) =>
      camera.pitch == 0 ? _fitUnpitched(camera) : _fitPitched(camera);

  /// The ground under the padded viewport, as offsets from the center in
  /// projected pixels, has the same shape at every zoom, so the zoom follows
  /// from the ratio of its bounding box to the projected bounds.
  MapCamera _fitPitched(MapCamera camera) {
    final viewport = padding.deflateRect(Offset.zero & camera.nonRotatedSize);
    final ground = [
      viewport.topLeft,
      viewport.topRight,
      viewport.bottomRight,
      viewport.bottomLeft,
    ].map(camera.groundOffsetFromCenter);
    if (ground.contains(null)) return camera;
    final visible = RectExtension.containing(ground.nonNulls.toList());

    final projectedBounds = Rect.fromPoints(
      camera.projectAtZoom(bounds.southEast),
      camera.projectAtZoom(bounds.northWest),
    );
    final scale = math.max(
      visible.width / projectedBounds.width,
      visible.height / projectedBounds.height,
    );
    var newZoom = camera.zoom + math.log(scale) / math.ln2;
    if (forceIntegerZoomLevel) newZoom = newZoom.ceilToDouble();
    newZoom = newZoom.clamp(
      math.max(camera.minZoom ?? 0, minZoom),
      math.min(camera.maxZoom ?? double.infinity, maxZoom ?? double.infinity),
    );

    final boundsCenter = Rect.fromPoints(
      camera.projectAtZoom(bounds.southEast, newZoom),
      camera.projectAtZoom(bounds.northWest, newZoom),
    ).center;
    return camera.withPosition(
      center: camera.unprojectAtZoom(boundsCenter - visible.center, newZoom),
      zoom: newZoom,
    );
  }

  MapCamera _fitUnpitched(MapCamera camera) {
    final paddingTL = Offset(padding.left, padding.top);
    final paddingBR = Offset(padding.right, padding.bottom);
    final paddingTotalXY = paddingTL + paddingBR;
    final paddingOffset = (paddingBR - paddingTL) / 2;

    final cameraSize = camera.nonRotatedSize - paddingTotalXY as Size;

    final projectedBoundsSize = Rect.fromPoints(
      camera.projectAtZoom(bounds.southEast, camera.zoom),
      camera.projectAtZoom(bounds.northWest, camera.zoom),
    ).size;

    final scale = _rectInRotRectScale(
      angleRad: camera.rotationRad,
      smallRectHalfWidth: cameraSize.width / 2.0,
      smallRectHalfHeight: cameraSize.height / 2.0,
      bigRectHalfWidth: projectedBoundsSize.width / 2.0,
      bigRectHalfHeight: projectedBoundsSize.height / 2.0,
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
    required Offset paddingOffset,
  }) {
    if (camera.rotation == 0.0) {
      final swPoint = camera.projectAtZoom(bounds.southWest, newZoom);
      final nePoint = camera.projectAtZoom(bounds.northEast, newZoom);
      final projectedCenter = (swPoint + nePoint) / 2 + paddingOffset;
      final newCenter = camera.unprojectAtZoom(projectedCenter, newZoom);

      return newCenter;
    }

    // Handle rotation
    final projectedCenter = camera.projectAtZoom(bounds.center, newZoom);
    final rotatedCenter = projectedCenter.rotate(-camera.rotationRad);
    final adjustedCenter = rotatedCenter + paddingOffset;
    final derotatedAdjustedCenter = adjustedCenter.rotate(camera.rotationRad);
    final newCenter = camera.unprojectAtZoom(derotatedAdjustedCenter, newZoom);

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
    final normalizedAngleRad = _normalize(angleRad, 0, 2.0 * math.pi);

    var kmin = double.infinity;
    final quadrant = (2.0 * normalizedAngleRad / math.pi).floor();
    if (quadrant.isOdd) {
      final px = bigRectHalfWidth * math.cos(normalizedAngleRad) +
          bigRectHalfHeight * math.sin(normalizedAngleRad);
      final py = bigRectHalfWidth * math.sin(normalizedAngleRad) -
          bigRectHalfHeight * math.cos(normalizedAngleRad);
      final dx = -math.cos(normalizedAngleRad);
      final dy = -math.sin(normalizedAngleRad);

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
      final px = bigRectHalfWidth * math.cos(normalizedAngleRad) -
          bigRectHalfHeight * math.sin(normalizedAngleRad);
      final py = bigRectHalfWidth * math.sin(normalizedAngleRad) +
          bigRectHalfHeight * math.cos(normalizedAngleRad);
      final dx = math.sin(normalizedAngleRad);
      final dy = -math.cos(normalizedAngleRad);
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
    if (camera.pitch == 0) return _fitUnpitched(camera);
    return _fitPitched(
      camera,
      coordinates,
      padding,
      start: _fitUnpitched(camera.withPitch(0)).withPitch(camera.pitch),
      limitZoom: (zoom) => _limitZoom(
        camera,
        zoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
        forceIntegerZoomLevel: forceIntegerZoomLevel,
      ),
    );
  }

  MapCamera _fitUnpitched(MapCamera camera) {
    final paddingTL = Offset(padding.left, padding.top);
    final paddingBR = Offset(padding.right, padding.bottom);

    final paddingTotalXY = paddingTL + paddingBR;

    var newZoom = _getCoordinatesZoom(camera, paddingTotalXY);
    if (maxZoom != null) newZoom = math.min(maxZoom!, newZoom);

    final projectedPoints =
        coordinates.map((coord) => camera.projectAtZoom(coord, newZoom));

    final rotatedBounds = RectExtension.containing(projectedPoints
        .map((point) => point.rotate(-camera.rotationRad))
        .toList());

    // Apply padding
    final paddingOffset = (paddingBR - paddingTL) / 2;
    final rotatedNewCenter = rotatedBounds.center + paddingOffset;

    // Undo the rotation
    final unrotatedNewCenter = rotatedNewCenter.rotate(camera.rotationRad);

    final newCenter = camera.unprojectAtZoom(unrotatedNewCenter, newZoom);

    return camera.withPosition(
      center: newCenter,
      zoom: newZoom,
    );
  }

  double _getCoordinatesZoom(
    MapCamera camera,
    Offset pixelPadding,
  ) {
    var size = camera.nonRotatedSize - pixelPadding as Size;
    // Prevent negative size which results in NaN zoom value later on in the calculation
    size = Size(math.max(0, size.width), math.max(0, size.height));

    final projectedPoints = [
      for (final coord in coordinates) camera.projectAtZoom(coord)
    ];

    final rotatedBounds = RectExtension.containing(projectedPoints
        .map((point) => point.rotate(-camera.rotationRad))
        .toList());

    final boundsSize = rotatedBounds.size;

    // TODO this could be replaced with Size.shortestSide
    final scaleX = size.width / boundsSize.width;
    final scaleY = size.height / boundsSize.height;
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

/// The zoom limits of a fit, applied to [zoom].
double _limitZoom(
  MapCamera camera,
  double zoom, {
  required double minZoom,
  required double? maxZoom,
  required bool forceIntegerZoomLevel,
}) {
  final limited = forceIntegerZoomLevel ? zoom.floorToDouble() : zoom;
  return limited.clamp(
    math.max(camera.minZoom ?? 0, minZoom),
    math.min(camera.maxZoom ?? double.infinity, maxZoom ?? double.infinity),
  );
}

/// The camera, with the rotation and pitch of [start], at which [points] lie
/// inside the viewport reduced by [padding], at the largest zoom that
/// [limitZoom] allows.
///
/// Starts from [start] and repeats one step until it converges: move the
/// center so that the middle of the points' screen extent is at the middle of
/// the padded viewport, and change the zoom by the ratio of the two extents.
MapCamera _fitPitched(
  MapCamera camera,
  List<LatLng> points,
  EdgeInsets padding, {
  required MapCamera start,
  required double Function(double zoom) limitZoom,
}) {
  final target = padding.deflateRect(Offset.zero & camera.nonRotatedSize);
  if (target.width <= 0 || target.height <= 0 || points.isEmpty) return start;

  var fitted = start;
  var zoomChange = double.infinity;
  for (var i = 0; i < 20 && zoomChange.abs() >= 1e-4; i++) {
    final extent = _screenExtent(fitted, points);
    if (extent == null) {
      zoomChange = -1;
    } else {
      fitted = _centered(fitted, extent.center, target.center);
      final scale = math.min(
        target.width / extent.width,
        target.height / extent.height,
      );
      zoomChange = scale.isFinite ? math.log(scale) / math.ln2 : 0;
    }
    fitted = fitted.withPosition(zoom: fitted.zoom + zoomChange);
  }

  fitted = fitted.withPosition(zoom: limitZoom(fitted.zoom));
  for (var i = 0; i < 20; i++) {
    final extent = _screenExtent(fitted, points);
    if (extent == null || (extent.center - target.center).distance < 0.1) {
      break;
    }
    fitted = _centered(fitted, extent.center, target.center);
  }
  return fitted;
}

/// The bounding rectangle of the screen positions of [points], or null if a
/// point is behind the camera.
Rect? _screenExtent(MapCamera camera, List<LatLng> points) {
  final transform = camera.pixelToScreenTransform;
  final positions = <Offset>[];
  for (final point in points) {
    final projected = camera.projectAtZoom(point);
    final w = transform.entry(3, 0) * projected.dx +
        transform.entry(3, 1) * projected.dy +
        transform.entry(3, 3);
    if (w <= 0) return null;
    positions.add(MatrixUtils.transformPoint(transform, projected));
  }
  return RectExtension.containing(positions);
}

/// [camera] with its center moved so that the ground under the screen
/// position [from] is at [to].
MapCamera _centered(MapCamera camera, Offset from, Offset to) {
  final fromGround = camera.groundOffsetFromCenter(from);
  final toGround = camera.groundOffsetFromCenter(to);
  if (fromGround == null || toGround == null) return camera;
  return camera.withPosition(
    center: camera.unprojectAtZoom(
      camera.projectAtZoom(camera.center) + fromGround - toGround,
    ),
  );
}
