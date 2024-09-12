import 'dart:math' as math hide Point;
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/inherited_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart';

/// Describes the view of a map. This includes the size/zoom/position/crs as
/// well as the minimum/maximum zoom. This class is mostly immutable but has
/// some fields that get calculated lazily, changes to the map view may occur
/// via the [MapController] or user interactions which will result in a
/// new [MapCamera] value.
class MapCamera {
  /// During Flutter startup the native platform resolution is not immediately
  /// available which can cause constraints to be zero before they are updated
  /// in a subsequent build to the actual constraints. We set the size to this
  /// impossible (negative) value initially and only change it once Flutter
  /// provides real constraints.
  static const kImpossibleSize = Point<double>(-1, -1);

  /// The used coordinate reference system
  final Crs crs;

  /// The minimum allowed zoom level.
  final double? minZoom;

  /// The maximum allowed zoom level.
  final double? maxZoom;

  /// The [LatLng] which corresponds with the center of this camera.
  final LatLng center;

  /// How far zoomed this camera is.
  final double zoom;

  /// The rotation, in degrees, of the camera. See [rotationRad] for the same
  /// value in radians.
  final double rotation;

  /// The size of the map view ignoring rotation. This will be the size of the
  /// FlutterMap widget.
  final Point<double> nonRotatedSize;

  /// Lazily calculated field
  Point<double>? _cameraSize;

  /// Lazily calculated field
  Bounds<double>? _pixelBounds;

  /// Lazily calculated field
  LatLngBounds? _bounds;

  /// Lazily calculated field
  Point<double>? _pixelOrigin;

  /// This is the [LatLngBounds] corresponding to four corners of this camera.
  /// This takes rotation in to account.
  LatLngBounds get visibleBounds => _bounds ??= LatLngBounds(
        unproject(pixelBounds.bottomLeft, zoom),
        unproject(pixelBounds.topRight, zoom),
      );

  /// The size of bounding box of this camera taking in to account its
  /// rotation. When the rotation is zero this will equal [nonRotatedSize],
  /// otherwise it will be the size of the rectangle which contains this
  /// camera.
  Point<double> get size => _cameraSize ??= calculateRotatedSize(
        rotation,
        nonRotatedSize,
      );

  /// The offset of the top-left corner of the bounding rectangle of this
  /// camera. This will not equal the offset of the top-left visible pixel when
  /// the map is rotated.
  Point<double> get pixelOrigin =>
      _pixelOrigin ??= project(center, zoom) - size / 2.0;

  /// The camera of the closest [FlutterMap] ancestor. If this is called from a
  /// context with no [FlutterMap] ancestor null, is returned.
  static MapCamera? maybeOf(BuildContext context) =>
      MapInheritedModel.maybeCameraOf(context);

  /// The camera of the closest [FlutterMap] ancestor. If this is called from a
  /// context with no [FlutterMap] ancestor a [StateError] will be thrown.
  static MapCamera of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError(
          '`MapCamera.of()` should not be called outside a `FlutterMap` and its descendants'));

  /// Create an instance of [MapCamera]. The [pixelOrigin], [bounds], and
  /// [pixelBounds] may be set if they are known already. Otherwise if left
  /// null they will be calculated lazily when they are used.
  MapCamera({
    required this.crs,
    required this.center,
    required this.zoom,
    required this.rotation,
    required this.nonRotatedSize,
    this.minZoom,
    this.maxZoom,
    Point<double>? size,
    Bounds<double>? pixelBounds,
    LatLngBounds? bounds,
    Point<double>? pixelOrigin,
  })  : _cameraSize = size,
        _pixelBounds = pixelBounds,
        _bounds = bounds,
        _pixelOrigin = pixelOrigin;

  /// Initializes [MapCamera] from the given [options] and with the
  /// [nonRotatedSize] set to [kImpossibleSize].
  MapCamera.initialCamera(MapOptions options)
      : crs = options.crs,
        minZoom = options.minZoom,
        maxZoom = options.maxZoom,
        center = options.initialCenter,
        zoom = options.initialZoom,
        rotation = options.initialRotation,
        nonRotatedSize = kImpossibleSize;

  /// Returns a new instance of [MapCamera] with the given [nonRotatedSize].
  MapCamera withNonRotatedSize(Point<double> nonRotatedSize) {
    if (nonRotatedSize == this.nonRotatedSize) return this;

    return MapCamera(
      crs: crs,
      center: center,
      zoom: zoom,
      rotation: rotation,
      nonRotatedSize: nonRotatedSize,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// Returns a new instance of [MapCamera] with the given [rotation].
  MapCamera withRotation(double rotation) {
    if (rotation == this.rotation) return this;

    return MapCamera(
      crs: crs,
      center: center,
      zoom: zoom,
      nonRotatedSize: nonRotatedSize,
      rotation: rotation,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// Returns a new instance of [MapCamera] with the given [options].
  MapCamera withOptions(MapOptions options) {
    if (options.crs == crs &&
        options.minZoom == minZoom &&
        options.maxZoom == maxZoom) {
      return this;
    }

    return MapCamera(
      crs: options.crs,
      minZoom: options.minZoom,
      maxZoom: options.maxZoom,
      center: center,
      zoom: zoom,
      rotation: rotation,
      nonRotatedSize: nonRotatedSize,
      size: _cameraSize,
    );
  }

  /// Returns a new instance of [MapCamera] with the given [center]/[zoom].
  MapCamera withPosition({
    LatLng? center,
    double? zoom,
  }) =>
      MapCamera(
        crs: crs,
        minZoom: minZoom,
        maxZoom: maxZoom,
        center: _adjustPositionForSeamlessScrolling(center),
        zoom: zoom ?? this.zoom,
        rotation: rotation,
        nonRotatedSize: nonRotatedSize,
        size: _cameraSize,
      );

  /// Jumps camera to opposite side of the world to enable seamless scrolling
  /// between 180 and -180 longitude.
  LatLng _adjustPositionForSeamlessScrolling(LatLng? position) {
    if (position == null) {
      return center;
    }
    double adjustedLongitude = position.longitude;
    if (adjustedLongitude >= 180.0) {
      adjustedLongitude -= 360.0;
    } else if (adjustedLongitude <= -180.0) {
      adjustedLongitude += 360.0;
    }
    return adjustedLongitude == position.longitude
        ? position
        : LatLng(position.latitude, adjustedLongitude);
  }

  /// Calculates the size of a bounding box which surrounds a box of size
  /// [nonRotatedSize] which is rotated by [rotation].
  static Point<double> calculateRotatedSize(
    double rotation,
    Point<double> nonRotatedSize,
  ) {
    if (rotation == 0.0) return nonRotatedSize;

    final rotationRad = degrees2Radians * rotation;
    final cosAngle = math.cos(rotationRad).abs();
    final sinAngle = math.sin(rotationRad).abs();
    final width = (nonRotatedSize.x * cosAngle) + (nonRotatedSize.y * sinAngle);
    final height =
        (nonRotatedSize.y * cosAngle) + (nonRotatedSize.x * sinAngle);

    return Point<double>(width, height);
  }

  /// The current rotation value in radians
  double get rotationRad => rotation * degrees2Radians;

  /// Calculates point value for the given [latlng] using this camera's
  /// [crs] and [zoom] (or the provided [zoom]).
  Point<double> project(LatLng latlng, [double? zoom]) =>
      crs.latLngToPoint(latlng, zoom ?? this.zoom);

  /// Calculates the [LatLng] for the given [point] using this camera's
  /// [crs] and [zoom] (or the provided [zoom]).
  LatLng unproject(Point point, [double? zoom]) =>
      crs.pointToLatLng(point, zoom ?? this.zoom);

  /// Same as the [unproject] function.
  LatLng layerPointToLatLng(Point point) => unproject(point);

  /// Calculates the scale for a zoom from [fromZoom] to [toZoom] using this
  /// camera\s [crs].
  double getZoomScale(double toZoom, double fromZoom) =>
      crs.scale(toZoom) / crs.scale(fromZoom);

  /// Calculates the scale for this camera's [zoom].
  double getScaleZoom(double scale) => crs.zoom(scale * crs.scale(zoom));

  /// Calculates the pixel bounds of this camera's [crs].
  Bounds? getPixelWorldBounds(double? zoom) =>
      crs.getProjectedBounds(zoom ?? this.zoom);

  /// Calculates the [Offset] from the [pos] to this camera's [pixelOrigin].
  Offset getOffsetFromOrigin(LatLng pos) =>
      (project(pos) - pixelOrigin).toOffset();

  /// Calculates the pixel origin of this [MapCamera] at the given
  /// [center]/[zoom].
  Point<int> getNewPixelOrigin(LatLng center, [double? zoom]) {
    final halfSize = size / 2.0;
    return (project(center, zoom) - halfSize).round();
  }

  /// Calculates the pixel bounds of this [MapCamera]. This value is cached.
  Bounds<double> get pixelBounds =>
      _pixelBounds ?? (_pixelBounds = pixelBoundsAtZoom(zoom));

  /// Calculates the pixel bounds of this [MapCamera] at the given [zoom].
  Bounds<double> pixelBoundsAtZoom(double zoom) {
    var halfSize = size / 2;
    if (zoom != this.zoom) {
      final scale = getZoomScale(this.zoom, zoom);
      halfSize = size / (scale * 2);
    }
    final pixelCenter = project(center, zoom).floor().toDoublePoint();
    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

  /// This will convert a latLng to a position that we could use with a widget
  /// outside of FlutterMap layer space. Eg using a Positioned Widget.
  Point<double> latLngToScreenPoint(LatLng latLng) {
    final nonRotatedPixelOrigin = project(center, zoom) - nonRotatedSize / 2.0;

    var point = crs.latLngToPoint(latLng, zoom);

    final mapCenter = crs.latLngToPoint(center, zoom);

    if (rotation != 0.0) {
      point = rotatePoint(mapCenter, point, counterRotation: false);
    }

    return point - nonRotatedPixelOrigin;
  }

  /// Calculate the [LatLng] coordinates for a [localPoint].
  LatLng pointToLatLng(Point localPoint) {
    final localPointCenterDistance = Point(
      (nonRotatedSize.x / 2) - localPoint.x,
      (nonRotatedSize.y / 2) - localPoint.y,
    );
    final mapCenter = crs.latLngToPoint(center, zoom);

    var point = mapCenter - localPointCenterDistance;

    if (rotation != 0.0) {
      point = rotatePoint(mapCenter, point);
    }

    return crs.pointToLatLng(point, zoom);
  }

  /// Sometimes we need to make allowances that a rotation already exists, so
  /// it needs to be reversed (pointToLatLng), and sometimes we want to use
  /// the same rotation to create a new position (latLngToScreenpoint).
  /// counterRotation just makes allowances this for this.
  Point<double> rotatePoint(
    Point<double> mapCenter,
    Point<double> point, {
    bool counterRotation = true,
  }) {
    final counterRotationFactor = counterRotation ? -1 : 1;

    final m = Matrix4.identity()
      ..translate(mapCenter.x, mapCenter.y)
      ..rotateZ(rotationRad * counterRotationFactor)
      ..translate(-mapCenter.x, -mapCenter.y);

    final tp = MatrixUtils.transformPoint(m, point.toOffset());

    return Point(tp.dx, tp.dy);
  }

  /// Clamps the provided [zoom] to the range specified by [minZoom] and
  /// [maxZoom], if set.
  double clampZoom(double zoom) => zoom.clamp(
        minZoom ?? double.negativeInfinity,
        maxZoom ?? double.infinity,
      );

  /// Calculate the [LatLng] coordinates for a given [Offset] and an optional
  /// zoom level. If [zoom] is not provided the current zoom level of the
  /// [MapCamera] gets used.
  LatLng offsetToCrs(Offset offset, [double? zoom]) {
    final focalStartPt = project(center, zoom ?? this.zoom);
    final point =
        (offset.toPoint() - (nonRotatedSize / 2.0)).rotate(rotationRad);

    final newCenterPt = focalStartPt + point;
    return unproject(newCenterPt, zoom ?? this.zoom);
  }

  /// Calculate the center point which would keep the same point of the map
  /// visible at the given [cursorPos] with the zoom set to [zoom].
  LatLng focusedZoomCenter(Point cursorPos, double zoom) {
    // Calculate offset of mouse cursor from viewport center
    final viewCenter = nonRotatedSize / 2;
    final offset = (cursorPos - viewCenter).rotate(rotationRad);
    // Match new center coordinate to mouse cursor position
    final scale = getZoomScale(zoom, this.zoom);
    final newOffset = offset * (1.0 - 1.0 / scale);
    final mapCenter = project(center);
    final newCenter = unproject(mapCenter + newOffset);
    return newCenter;
  }

  @override
  int get hashCode => Object.hash(
      crs, minZoom, maxZoom, center, zoom, rotation, nonRotatedSize);

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      (other is MapCamera &&
          other.crs == crs &&
          other.minZoom == minZoom &&
          other.maxZoom == maxZoom &&
          other.center == center &&
          other.zoom == zoom &&
          other.rotation == rotation &&
          other.nonRotatedSize == nonRotatedSize);
}
