import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/misc/extensions.dart';
import 'package:latlong2/latlong.dart';

/// Describes a position for a [MapCamera]
///
/// Constraints are handled by [CameraConstraint].
///
/// The built-in fits fit at the current pitch and rotation.
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
  MapCamera fit(MapCamera camera) => _fitPoints(
        camera,
        [
          bounds.northWest,
          bounds.northEast,
          bounds.southEast,
          bounds.southWest,
        ],
        padding,
        minZoom: minZoom,
        maxZoom: maxZoom,
        forceIntegerZoomLevel: forceIntegerZoomLevel,
      );
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

  /// The ground under the padded viewport, as offsets from the center in
  /// projected pixels, has the same shape at every zoom, so the zoom follows
  /// from the ratio of its bounding box to the projected bounds.
  @override
  MapCamera fit(MapCamera camera) {
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
    var newZoom = camera.getScaleZoom(scale);
    if (forceIntegerZoomLevel) newZoom = newZoom.ceilToDouble();
    newZoom = _clampZoom(camera, newZoom, minZoom: minZoom, maxZoom: maxZoom);

    final boundsCenter = Rect.fromPoints(
      camera.projectAtZoom(bounds.southEast, newZoom),
      camera.projectAtZoom(bounds.northWest, newZoom),
    ).center;
    return camera.withPosition(
      center: camera.unprojectAtZoom(boundsCenter - visible.center, newZoom),
      zoom: newZoom,
    );
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
  MapCamera fit(MapCamera camera) => _fitPoints(
        camera,
        coordinates,
        padding,
        minZoom: minZoom,
        maxZoom: maxZoom,
        forceIntegerZoomLevel: forceIntegerZoomLevel,
      );
}

/// [zoom] limited to the zoom limits of [camera] and of a fit.
double _clampZoom(
  MapCamera camera,
  double zoom, {
  required double minZoom,
  required double? maxZoom,
}) =>
    zoom.clamp(
      math.max(camera.minZoom ?? 0, minZoom),
      math.min(camera.maxZoom ?? double.infinity, maxZoom ?? double.infinity),
    );

/// The fit of [points] for [FitBounds] and [FitCoordinates].
MapCamera _fitPoints(
  MapCamera camera,
  List<LatLng> points,
  EdgeInsets padding, {
  required double minZoom,
  required double? maxZoom,
  required bool forceIntegerZoomLevel,
}) =>
    _fitPitched(
      camera,
      points,
      padding,
      start: _ratioStep(
        camera,
        points,
        padding,
        clampZoom: (zoom) =>
            _clampZoom(camera, zoom, minZoom: minZoom, maxZoom: maxZoom),
      ),
      limitZoom: (zoom) => _clampZoom(
        camera,
        forceIntegerZoomLevel ? zoom.floorToDouble() : zoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
      ),
    );

/// The start of the search of [_fitPitched]: [camera] at pitch 0 with its zoom
/// changed by the scale at which the screen extent of [points] fits the
/// viewport reduced by [padding], and that extent centered in it, at the pitch
/// of [camera].
///
/// At pitch 0 the screen extent scales with the zoom scale, so this is the
/// largest zoom at which [points] fit.
MapCamera _ratioStep(
  MapCamera camera,
  List<LatLng> points,
  EdgeInsets padding, {
  required double Function(double zoom) clampZoom,
}) {
  if (points.isEmpty) return camera;
  final unpitched = camera.withPitch(0);
  final target = padding.deflateRect(Offset.zero & camera.nonRotatedSize);
  // At pitch 0 no point is behind the camera
  final extent = _screenExtent(unpitched, points)!;
  final scale = math.min(
    math.max(0, target.width) / extent.width,
    math.max(0, target.height) / extent.height,
  );
  final zoomed =
      unpitched.withPosition(zoom: clampZoom(unpitched.getScaleZoom(scale)));
  final zoomedExtent = _screenExtent(zoomed, points)!;
  return _centered(zoomed, zoomedExtent.center, target.center)
      .withPitch(camera.pitch);
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
