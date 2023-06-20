import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/src/geo/crs.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/map/inherited_model.dart';
import 'package:flutter_map/src/map/options.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';
import 'package:latlong2/latlong.dart';

class MapCamera {
  // During Flutter startup the native platform resolution is not immediately
  // available which can cause constraints to be zero before they are updated
  // in a subsequent build to the actual constraints. We set the size to this
  // impossible (negative) value initially and only change it once Flutter
  // provides real constraints.
  static const kImpossibleSize = CustomPoint<double>(-1, -1);

  final Crs crs;
  final double? minZoom;
  final double? maxZoom;

  final LatLng center;
  final double zoom;
  final double rotation;

  // Original size of the map where rotation isn't calculated
  final CustomPoint<double> nonRotatedSize;

  // Lazily calculated fields.
  CustomPoint<double>? _cameraSize;
  Bounds<double>? _pixelBounds;
  LatLngBounds? _bounds;
  CustomPoint<int>? _pixelOrigin;
  double? _rotationRad;

  static MapCamera? maybeOf(BuildContext context) =>
      FlutterMapInheritedModel.maybeCameraOf(context);

  static MapCamera of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError(
          '`MapCamera.of()` should not be called outside a `FlutterMap` and its descendants'));

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

  // Create an instance of [MapCamera]. The [pixelOrigin], [bounds], and
  // [pixelBounds] may be set if they are known already. Otherwise if left
  // null they will be calculated lazily when they are used.
  MapCamera({
    required this.crs,
    required this.center,
    required this.zoom,
    required this.rotation,
    required this.nonRotatedSize,
    this.minZoom,
    this.maxZoom,
    CustomPoint<double>? size,
    Bounds<double>? pixelBounds,
    LatLngBounds? bounds,
    CustomPoint<int>? pixelOrigin,
  })  : _cameraSize = size ?? calculateRotatedSize(rotation, nonRotatedSize),
        _pixelBounds = pixelBounds,
        _bounds = bounds,
        _pixelOrigin = pixelOrigin;

  MapCamera withNonRotatedSize(CustomPoint<double> nonRotatedSize) {
    if (nonRotatedSize == this.nonRotatedSize) return this;

    return MapCamera(
      crs: crs,
      minZoom: minZoom,
      maxZoom: maxZoom,
      center: center,
      zoom: zoom,
      rotation: rotation,
      nonRotatedSize: nonRotatedSize,
    );
  }

  MapCamera withRotation(double rotation) {
    if (rotation == this.rotation) return this;

    return MapCamera(
      crs: crs,
      minZoom: minZoom,
      maxZoom: maxZoom,
      center: center,
      zoom: zoom,
      rotation: rotation,
      nonRotatedSize: nonRotatedSize,
    );
  }

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

  MapCamera withPosition({
    LatLng? center,
    double? zoom,
  }) =>
      MapCamera(
        crs: crs,
        minZoom: minZoom,
        maxZoom: maxZoom,
        center: center ?? this.center,
        zoom: zoom ?? this.zoom,
        rotation: rotation,
        nonRotatedSize: nonRotatedSize,
        size: _cameraSize,
      );

  @Deprecated('Use visibleBounds instead.')
  LatLngBounds get bounds => visibleBounds;

  LatLngBounds get visibleBounds =>
      _bounds ??
      (_bounds = LatLngBounds(
        unproject(pixelBounds.bottomLeft, zoom),
        unproject(pixelBounds.topRight, zoom),
      ));

  CustomPoint<double> get size =>
      _cameraSize ??
      calculateRotatedSize(
        rotation,
        nonRotatedSize,
      );

  CustomPoint<int> get pixelOrigin =>
      _pixelOrigin ??
      (_pixelOrigin = (project(center, zoom) - size / 2.0).round());

  static CustomPoint<double> calculateRotatedSize(
    double rotation,
    CustomPoint<double> nonRotatedSize,
  ) {
    if (rotation == 0.0) return nonRotatedSize;

    final rotationRad = degToRadian(rotation);
    final cosAngle = math.cos(rotationRad).abs();
    final sinAngle = math.sin(rotationRad).abs();
    final width = (nonRotatedSize.x * cosAngle) + (nonRotatedSize.y * sinAngle);
    final height =
        (nonRotatedSize.y * cosAngle) + (nonRotatedSize.x * sinAngle);

    return CustomPoint<double>(width, height);
  }

  double get rotationRad => _rotationRad ??= degToRadian(rotation);

  CustomPoint<double> project(LatLng latlng, [double? zoom]) =>
      crs.latLngToPoint(latlng, zoom ?? this.zoom);

  LatLng unproject(CustomPoint point, [double? zoom]) =>
      crs.pointToLatLng(point, zoom ?? this.zoom);

  LatLng layerPointToLatLng(CustomPoint point) => unproject(point);

  double getZoomScale(double toZoom, double fromZoom) =>
      crs.scale(toZoom) / crs.scale(fromZoom);

  double getScaleZoom(double scale, double? fromZoom) =>
      crs.zoom(scale * crs.scale(fromZoom ?? zoom));

  Bounds? getPixelWorldBounds(double? zoom) =>
      crs.getProjectedBounds(zoom ?? this.zoom);

  Offset getOffsetFromOrigin(LatLng pos) {
    final delta = project(pos) - pixelOrigin;
    return Offset(delta.x, delta.y);
  }

  CustomPoint<int> getNewPixelOrigin(LatLng center, [double? zoom]) {
    final halfSize = size / 2.0;
    return (project(center, zoom) - halfSize).round();
  }

  Bounds<double> get pixelBounds =>
      _pixelBounds ?? (_pixelBounds = pixelBoundsAtZoom(zoom));

  Bounds<double> pixelBoundsAtZoom(double zoom) {
    CustomPoint<double> halfSize = size / 2;
    if (zoom != this.zoom) {
      final scale = getZoomScale(this.zoom, zoom);
      halfSize = size / (scale * 2);
    }
    final pixelCenter = project(center, zoom).floor().toDoublePoint();
    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

  // This will convert a latLng to a position that we could use with a widget
  // outside of FlutterMap layer space. Eg using a Positioned Widget.
  CustomPoint<double> latLngToScreenPoint(LatLng latLng) {
    final nonRotatedPixelOrigin =
        (project(center, zoom) - nonRotatedSize / 2.0).round();

    var point = crs.latLngToPoint(latLng, zoom);

    final mapCenter = crs.latLngToPoint(center, zoom);

    if (rotation != 0.0) {
      point = rotatePoint(mapCenter, point, counterRotation: false);
    }

    return point - nonRotatedPixelOrigin;
  }

  LatLng pointToLatLng(CustomPoint localPoint) {
    final localPointCenterDistance = CustomPoint(
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

  // Sometimes we need to make allowances that a rotation already exists, so
  // it needs to be reversed (pointToLatLng), and sometimes we want to use
  // the same rotation to create a new position (latLngToScreenpoint).
  // counterRotation just makes allowances this for this.
  CustomPoint<double> rotatePoint(
    CustomPoint<double> mapCenter,
    CustomPoint<double> point, {
    bool counterRotation = true,
  }) {
    final counterRotationFactor = counterRotation ? -1 : 1;

    final m = Matrix4.identity()
      ..translate(mapCenter.x, mapCenter.y)
      ..rotateZ(rotationRad * counterRotationFactor)
      ..translate(-mapCenter.x, -mapCenter.y);

    final tp = MatrixUtils.transformPoint(m, Offset(point.x, point.y));

    return CustomPoint(tp.dx, tp.dy);
  }

  double clampZoom(double zoom) => zoom.clamp(
        minZoom ?? double.negativeInfinity,
        maxZoom ?? double.infinity,
      );

  LatLng offsetToCrs(Offset offset, [double? zoom]) {
    final focalStartPt = project(center, zoom ?? this.zoom);
    final point =
        (offset.toCustomPoint() - (nonRotatedSize / 2.0)).rotate(rotationRad);

    final newCenterPt = focalStartPt + point;
    return unproject(newCenterPt, zoom ?? this.zoom);
  }

  // Calculate the center point which would keep the same point of the map
  // visible at the given [cursorPos] with the zoom set to [zoom].
  LatLng focusedZoomCenter(CustomPoint cursorPos, double zoom) {
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
}
