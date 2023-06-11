import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/src/geo/crs.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/map/flutter_map_state_inherited_widget.dart';
import 'package:flutter_map/src/map/options.dart';
import 'package:flutter_map/src/misc/center_zoom.dart';
import 'package:flutter_map/src/misc/fit_bounds_options.dart';
import 'package:flutter_map/src/misc/map_boundary.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';
import 'package:latlong2/latlong.dart';

class FlutterMapState {
  // During Flutter startup the native platform resolution is not immediately
  // available which can cause constraints to be zero before they are updated
  // in a subsequent build to the actual constraints. We set the size to this
  // impossible (negative) value initially and only change it once Flutter
  // provides real constraints.
  static const kImpossibleSize = CustomPoint<double>(-1, -1);

  final Crs crs;
  final double? minZoom;
  final double? maxZoom;
  final MapBoundary? boundary;

  final LatLng center;
  final double zoom;
  final double rotation;

  // Original size of the map where rotation isn't calculated
  final CustomPoint<double> nonRotatedSize;

  // Extended size of the map where rotation is calculated
  final CustomPoint<double> size;

  // Lazily calculated fields.
  Bounds<double>? _pixelBounds;
  LatLngBounds? _bounds;
  CustomPoint<int>? _pixelOrigin;

  static FlutterMapState? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MapStateInheritedWidget>()
      ?.state;

  static FlutterMapState of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError(
          '`FlutterMapState.of()` should not be called outside a `FlutterMap` and its descendants'));

  /// Initializes FlutterMapState from the given [options] and with the
  /// [nonRotatedSize] and [size] both set to [kImpossibleSize].
  FlutterMapState.initialState(MapOptions options)
      : crs = options.crs,
        minZoom = options.minZoom,
        maxZoom = options.maxZoom,
        boundary = options.boundary,
        center = options.center,
        zoom = options.zoom,
        rotation = options.rotation,
        nonRotatedSize = kImpossibleSize,
        size = kImpossibleSize;

  // Create an instance of FlutterMapState. The [pixelOrigin], [bounds], and
  // [pixelBounds] may be set if they are known already. Otherwise if left
  // null they will be calculated lazily when they are used.
  FlutterMapState({
    required this.crs,
    required this.minZoom,
    required this.maxZoom,
    required this.boundary,
    required this.center,
    required this.zoom,
    required this.rotation,
    required this.nonRotatedSize,
    required this.size,
    Bounds<double>? pixelBounds,
    LatLngBounds? bounds,
    CustomPoint<int>? pixelOrigin,
  })  : _pixelBounds = pixelBounds,
        _bounds = bounds,
        _pixelOrigin = pixelOrigin;

  FlutterMapState withNonRotatedSize(CustomPoint<double> nonRotatedSize) {
    if (nonRotatedSize == this.nonRotatedSize) return this;

    return FlutterMapState(
      crs: crs,
      minZoom: minZoom,
      maxZoom: maxZoom,
      boundary: boundary,
      center: center,
      zoom: zoom,
      rotation: rotation,
      nonRotatedSize: nonRotatedSize,
      size: _calculateSize(rotation, nonRotatedSize),
    );
  }

  FlutterMapState withRotation(double rotation) {
    if (rotation == this.rotation) return this;

    return FlutterMapState(
      crs: crs,
      minZoom: minZoom,
      maxZoom: maxZoom,
      boundary: boundary,
      center: center,
      zoom: zoom,
      rotation: rotation,
      nonRotatedSize: nonRotatedSize,
      size: _calculateSize(rotation, nonRotatedSize),
    );
  }

  FlutterMapState withOptions(MapOptions options) {
    if (options.crs == crs &&
        options.minZoom == minZoom &&
        options.maxZoom == maxZoom &&
        options.boundary == boundary) {
      return this;
    }

    return FlutterMapState(
      crs: options.crs,
      minZoom: options.minZoom,
      maxZoom: options.maxZoom,
      boundary: options.boundary,
      center: center,
      zoom: zoom,
      rotation: rotation,
      nonRotatedSize: nonRotatedSize,
      size: _calculateSize(rotation, nonRotatedSize),
    );
  }

  FlutterMapState withPosition({
    LatLng? center,
    double? zoom,
  }) =>
      FlutterMapState(
        crs: crs,
        minZoom: minZoom,
        maxZoom: maxZoom,
        boundary: boundary,
        center: center ?? this.center,
        zoom: zoom ?? this.zoom,
        rotation: rotation,
        nonRotatedSize: nonRotatedSize,
        size: size,
      );

  Bounds<double> get pixelBounds =>
      _pixelBounds ?? (_pixelBounds = getPixelBounds());

  @Deprecated('Use visibleBounds instead.')
  LatLngBounds get bounds => visibleBounds;

  LatLngBounds get visibleBounds =>
      _bounds ??
      (_bounds = LatLngBounds(
        unproject(pixelBounds.bottomLeft, zoom),
        unproject(pixelBounds.topRight, zoom),
      ));

  CustomPoint<int> get pixelOrigin =>
      _pixelOrigin ??
      (_pixelOrigin = (project(center, zoom) - size / 2.0).round());

  static CustomPoint<double> _calculateSize(
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

  double get rotationRad => degToRadian(rotation);

  CenterZoom centerZoomFitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  }) {
    final paddingTL =
        CustomPoint<double>(options.padding.left, options.padding.top);
    final paddingBR =
        CustomPoint<double>(options.padding.right, options.padding.bottom);

    final paddingTotalXY = paddingTL + paddingBR;

    var zoom = getBoundsZoom(
      bounds,
      paddingTotalXY,
      inside: options.inside,
      forceIntegerZoomLevel: options.forceIntegerZoomLevel,
    );
    zoom = math.min(options.maxZoom, zoom);

    final paddingOffset = (paddingBR - paddingTL) / 2;
    final swPoint = project(bounds.southWest, zoom);
    final nePoint = project(bounds.northEast, zoom);

    final CustomPoint<double> projectedCenter;
    if (rotation != 0.0) {
      final swPointRotated = swPoint.rotate(-rotationRad);
      final nePointRotated = nePoint.rotate(-rotationRad);
      final centerRotated =
          (swPointRotated + nePointRotated) / 2 + paddingOffset;

      projectedCenter = centerRotated.rotate(rotationRad);
    } else {
      projectedCenter = (swPoint + nePoint) / 2 + paddingOffset;
    }

    final center = unproject(projectedCenter, zoom);

    return CenterZoom(
      center: center,
      zoom: zoom,
    );
  }

  double getBoundsZoom(
    LatLngBounds bounds,
    CustomPoint<double> padding, {
    bool inside = false,
    bool forceIntegerZoomLevel = false,
  }) {
    final min = minZoom ?? 0.0;
    final max = maxZoom ?? double.infinity;
    final nw = bounds.northWest;
    final se = bounds.southEast;
    var size = nonRotatedSize - padding;
    // Prevent negative size which results in NaN zoom value later on in the calculation
    size = CustomPoint(math.max(0, size.x), math.max(0, size.y));
    var boundsSize = Bounds(project(se, zoom), project(nw, zoom)).size;
    if (rotation != 0.0) {
      final cosAngle = math.cos(rotationRad).abs();
      final sinAngle = math.sin(rotationRad).abs();
      boundsSize = CustomPoint<double>(
        (boundsSize.x * cosAngle) + (boundsSize.y * sinAngle),
        (boundsSize.y * cosAngle) + (boundsSize.x * sinAngle),
      );
    }

    final scaleX = size.x / boundsSize.x;
    final scaleY = size.y / boundsSize.y;
    final scale = inside ? math.max(scaleX, scaleY) : math.min(scaleX, scaleY);

    var boundsZoom = getScaleZoom(scale, zoom);

    if (forceIntegerZoomLevel) {
      boundsZoom =
          inside ? boundsZoom.ceilToDouble() : boundsZoom.floorToDouble();
    }

    return math.max(min, math.min(max, boundsZoom));
  }

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

  Bounds<double> getPixelBounds([double? zoom]) {
    CustomPoint<double> halfSize = size / 2;
    if (zoom != null) {
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

  double fitZoomToBounds(double zoom) {
    // Abide to min/max zoom
    if (maxZoom != null) {
      zoom = (zoom > maxZoom!) ? maxZoom! : zoom;
    }
    if (minZoom != null) {
      zoom = (zoom < minZoom!) ? minZoom! : zoom;
    }
    return zoom;
  }

  // Returns true if given [center] is outside of the allowed bounds.
  bool isOutOfBounds(LatLng latLng) {
    switch (boundary) {
      case FixedBoundary():
        return !(boundary as FixedBoundary).contains(latLng);
      case AdaptiveBoundary():
        return !(boundary as AdaptiveBoundary).contains(latLng, zoom);
      case null:
        return false;
    }
  }

  LatLng clampWithFallback(LatLng point, LatLng fallback) {
    switch (boundary) {
      case FixedBoundary():
        return (boundary as FixedBoundary).clamp(point);
      case AdaptiveBoundary():
        return (boundary as AdaptiveBoundary)
            .clampWithFallback(point, fallback, zoom);
      case null:
        return point;
    }
  }

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

  LatLng? adjustCenterIfOutsideMaxBounds(
    LatLng testCenter,
    double testZoom,
    LatLngBounds maxBounds,
  ) {
    LatLng? newCenter;

    final swPixel = project(maxBounds.southWest, testZoom);
    final nePixel = project(maxBounds.northEast, testZoom);

    final centerPix = project(testCenter, testZoom);

    final halfSizeX = size.x / 2;
    final halfSizeY = size.y / 2;

    // Try and find the edge value that the center could use to stay within
    // the maxBounds. This should be ok for panning. If we zoom, it is possible
    // there is no solution to keep all corners within the bounds. If the edges
    // are still outside the bounds, don't return anything.
    final leftOkCenter = math.min(swPixel.x, nePixel.x) + halfSizeX;
    final rightOkCenter = math.max(swPixel.x, nePixel.x) - halfSizeX;
    final topOkCenter = math.min(swPixel.y, nePixel.y) + halfSizeY;
    final botOkCenter = math.max(swPixel.y, nePixel.y) - halfSizeY;

    double? newCenterX;
    double? newCenterY;

    var wasAdjusted = false;

    if (centerPix.x < leftOkCenter) {
      wasAdjusted = true;
      newCenterX = leftOkCenter;
    } else if (centerPix.x > rightOkCenter) {
      wasAdjusted = true;
      newCenterX = rightOkCenter;
    }

    if (centerPix.y < topOkCenter) {
      wasAdjusted = true;
      newCenterY = topOkCenter;
    } else if (centerPix.y > botOkCenter) {
      wasAdjusted = true;
      newCenterY = botOkCenter;
    }

    if (!wasAdjusted) {
      return testCenter;
    }

    final newCx = newCenterX ?? centerPix.x;
    final newCy = newCenterY ?? centerPix.y;

    // Have a final check, see if the adjusted center is within maxBounds.
    // If not, give up.
    if (newCx < leftOkCenter ||
        newCx > rightOkCenter ||
        newCy < topOkCenter ||
        newCy > botOkCenter) {
      return null;
    } else {
      newCenter = unproject(CustomPoint(newCx, newCy), testZoom);
    }

    return newCenter;
  }
}
