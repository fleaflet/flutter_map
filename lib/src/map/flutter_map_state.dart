import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/src/geo/crs.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/map/flutter_map_state_inherited_widget.dart';
import 'package:flutter_map/src/map/options.dart';
import 'package:flutter_map/src/misc/center_zoom.dart';
import 'package:flutter_map/src/misc/fit_bounds_options.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';
import 'package:latlong2/latlong.dart';

class FlutterMapState {
  final MapOptions options;

  final LatLng center;
  final double zoom;
  final double rotation;

  // Original size of the map where rotation isn't calculated
  final CustomPoint<double> nonrotatedSize;

  // Extended size of the map where rotation is calculated
  final CustomPoint<double> size;

  late final CustomPoint<int> pixelOrigin;
  late final LatLngBounds bounds;
  late final Bounds<double> pixelBounds;

  final bool hasFitInitialBounds;

  FlutterMapState._({
    required this.options,
    required this.center,
    required this.zoom,
    required this.rotation,
    required this.nonrotatedSize,
    required this.size,
    required this.hasFitInitialBounds,
    required this.pixelOrigin,
    required this.bounds,
    required this.pixelBounds,
  });

  FlutterMapState({
    required this.options,
    required this.center,
    required this.zoom,
    required this.rotation,
    required this.nonrotatedSize,
    required this.size,
    required this.hasFitInitialBounds,
  }) {
    pixelBounds = _getPixelBoundsStatic(options.crs, size, center, zoom);
    bounds = LatLngBounds(
      options.crs.pointToLatLng(pixelBounds.bottomLeft, zoom),
      options.crs.pointToLatLng(pixelBounds.topRight, zoom),
    );
    final halfSize = size / 2.0;
    pixelOrigin = (project(center, zoom) - halfSize).round();
  }

  FlutterMapState copyWith({
    LatLng? center,
    double? zoom,
  }) =>
      FlutterMapState(
        options: options,
        center: center ?? this.center,
        zoom: zoom ?? this.zoom,
        rotation: rotation,
        nonrotatedSize: nonrotatedSize,
        size: size,
        hasFitInitialBounds: hasFitInitialBounds,
      );

  FlutterMapState withNonotatedSize(CustomPoint<double> nonrotatedSize) {
    if (nonrotatedSize == this.nonrotatedSize) return this;

    return FlutterMapState(
      options: options,
      center: center,
      zoom: zoom,
      rotation: rotation,
      nonrotatedSize: nonrotatedSize,
      size: _calculateSize(rotation, nonrotatedSize),
      hasFitInitialBounds: hasFitInitialBounds,
    );
  }

  FlutterMapState withRotation(double rotation) {
    if (rotation == this.rotation) return this;

    return FlutterMapState(
      options: options,
      center: center,
      zoom: zoom,
      rotation: rotation,
      nonrotatedSize: nonrotatedSize,
      size: _calculateSize(rotation, nonrotatedSize),
      hasFitInitialBounds: hasFitInitialBounds,
    );
  }

  FlutterMapState withOptions(MapOptions options) => FlutterMapState(
        options: options,
        center: center,
        zoom: zoom,
        rotation: rotation,
        nonrotatedSize: nonrotatedSize,
        size: _calculateSize(rotation, nonrotatedSize),
        hasFitInitialBounds: hasFitInitialBounds,
      );

  static CustomPoint<double> _calculateSize(
    double rotation,
    CustomPoint<double> nonrotatedSize,
  ) {
    if (rotation == 0.0) return nonrotatedSize;

    final rotationRad = degToRadian(rotation);
    final cosAngle = math.cos(rotationRad).abs();
    final sinAngle = math.sin(rotationRad).abs();
    final width = (nonrotatedSize.x * cosAngle) + (nonrotatedSize.y * sinAngle);
    final height =
        (nonrotatedSize.y * cosAngle) + (nonrotatedSize.x * sinAngle);

    return CustomPoint<double>(width, height);
  }

  double get rotationRad => degToRadian(rotation);

  CenterZoom centerZoomFitBounds(
    LatLngBounds bounds,
    FitBoundsOptions options,
  ) =>
      getBoundsCenterZoom(bounds, options);

  double getBoundsZoom(
    LatLngBounds bounds,
    CustomPoint<double> padding, {
    bool inside = false,
    bool forceIntegerZoomLevel = false,
  }) {
    final min = options.minZoom ?? 0.0;
    final max = options.maxZoom ?? double.infinity;
    final nw = bounds.northWest;
    final se = bounds.southEast;
    var size = nonrotatedSize - padding;
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

  CenterZoom getBoundsCenterZoom(
      LatLngBounds bounds, FitBoundsOptions options) {
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

  CustomPoint<double> project(LatLng latlng, [double? zoom]) =>
      options.crs.latLngToPoint(latlng, zoom ?? this.zoom);

  LatLng unproject(CustomPoint point, [double? zoom]) =>
      options.crs.pointToLatLng(point, zoom ?? this.zoom);

  LatLng layerPointToLatLng(CustomPoint point) => unproject(point);

  double getZoomScale(double toZoom, double fromZoom) =>
      options.crs.scale(toZoom) / options.crs.scale(fromZoom);

  double getScaleZoom(double scale, double? fromZoom) {
    final crs = options.crs;
    fromZoom = fromZoom ?? zoom;
    return crs.zoom(scale * crs.scale(fromZoom));
  }

  Bounds? getPixelWorldBounds(double? zoom) {
    return options.crs.getProjectedBounds(zoom ?? this.zoom);
  }

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

  static Bounds<double> _getPixelBoundsStatic(
    Crs crs,
    CustomPoint<double> size,
    LatLng center,
    double zoom,
  ) {
    final halfSize = size / 2;
    final pixelCenter = crs.latLngToPoint(center, zoom).floor().toDoublePoint();
    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

  // This will convert a latLng to a position that we could use with a widget
  // outside of FlutterMap layer space. Eg using a Positioned Widget.
  CustomPoint<double> latLngToScreenPoint(LatLng latLng) {
    final nonRotatedPixelOrigin =
        (project(center, zoom) - nonrotatedSize / 2.0).round();

    var point = options.crs.latLngToPoint(latLng, zoom);

    final mapCenter = options.crs.latLngToPoint(center, zoom);

    if (rotation != 0.0) {
      point = rotatePoint(mapCenter, point, counterRotation: false);
    }

    return point - nonRotatedPixelOrigin;
  }

  LatLng pointToLatLng(CustomPoint localPoint) {
    final localPointCenterDistance = CustomPoint(
      (nonrotatedSize.x / 2) - localPoint.x,
      (nonrotatedSize.y / 2) - localPoint.y,
    );
    final mapCenter = options.crs.latLngToPoint(center, zoom);

    var point = mapCenter - localPointCenterDistance;

    if (rotation != 0.0) {
      point = rotatePoint(mapCenter, point);
    }

    return options.crs.pointToLatLng(point, zoom);
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

  // TODO replicate old caching or stop doing it
  _SafeArea? _safeAreaCache;
  double? _safeAreaZoom;

  double fitZoomToBounds(double zoom) {
    // Abide to min/max zoom
    if (options.maxZoom != null) {
      zoom = (zoom > options.maxZoom!) ? options.maxZoom! : zoom;
    }
    if (options.minZoom != null) {
      zoom = (zoom < options.minZoom!) ? options.minZoom! : zoom;
    }
    return zoom;
  }

  //if there is a pan boundary, do not cross
  bool isOutOfBounds(LatLng center) {
    if (options.adaptiveBoundaries) {
      return !_safeArea!.contains(center);
    }
    if (options.swPanBoundary != null && options.nePanBoundary != null) {
      if (center.latitude < options.swPanBoundary!.latitude ||
          center.latitude > options.nePanBoundary!.latitude) {
        return true;
      } else if (center.longitude < options.swPanBoundary!.longitude ||
          center.longitude > options.nePanBoundary!.longitude) {
        return true;
      }
    }
    return false;
  }

  LatLng containPoint(LatLng point, LatLng fallback) {
    if (options.adaptiveBoundaries) {
      return _safeArea!.containPoint(point, fallback);
    } else {
      return LatLng(
        point.latitude.clamp(
            options.swPanBoundary!.latitude, options.nePanBoundary!.latitude),
        point.longitude.clamp(
            options.swPanBoundary!.longitude, options.nePanBoundary!.longitude),
      );
    }
  }

  _SafeArea? get _safeArea {
    if (zoom != _safeAreaZoom || _safeAreaCache == null) {
      _safeAreaZoom = zoom;
      final halfScreenHeight = calculateScreenHeightInDegrees() / 2;
      final halfScreenWidth = calculateScreenWidthInDegrees() / 2;
      final southWestLatitude =
          options.swPanBoundary!.latitude + halfScreenHeight;
      final southWestLongitude =
          options.swPanBoundary!.longitude + halfScreenWidth;
      final northEastLatitude =
          options.nePanBoundary!.latitude - halfScreenHeight;
      final northEastLongitude =
          options.nePanBoundary!.longitude - halfScreenWidth;
      _safeAreaCache = _SafeArea(
        LatLng(
          southWestLatitude,
          southWestLongitude,
        ),
        LatLng(
          northEastLatitude,
          northEastLongitude,
        ),
      );
    }
    return _safeAreaCache;
  }

  double calculateScreenWidthInDegrees() {
    final degreesPerPixel = 360 / math.pow(2, zoom + 8);
    return options.screenSize!.width * degreesPerPixel;
  }

  double calculateScreenHeightInDegrees() =>
      options.screenSize!.height * 170.102258 / math.pow(2, zoom + 8);

  LatLng offsetToCrs(Offset offset, [double? zoom]) {
    final focalStartPt = project(center, zoom ?? this.zoom);
    final point =
        (offsetToPoint(offset) - (nonrotatedSize / 2.0)).rotate(rotationRad);

    final newCenterPt = focalStartPt + point;
    return unproject(newCenterPt, zoom ?? this.zoom);
  }

  // TODO This can be an extension on offset or a constructor on CustomPoint.
  CustomPoint<double> offsetToPoint(Offset offset) {
    return CustomPoint(offset.dx, offset.dy);
  }

  List<dynamic> getNewEventCenterZoomPosition(
      CustomPoint cursorPos, double newZoom) {
    // Calculate offset of mouse cursor from viewport center
    final viewCenter = nonrotatedSize / 2;
    final offset = (cursorPos - viewCenter).rotate(rotationRad);
    // Match new center coordinate to mouse cursor position
    final scale = getZoomScale(newZoom, zoom);
    final newOffset = offset * (1.0 - 1.0 / scale);
    final mapCenter = project(center);
    final newCenter = unproject(mapCenter + newOffset);
    return <dynamic>[newCenter, newZoom];
  }

  LatLng? adjustCenterIfOutsideMaxBounds(
      LatLng testCenter, double testZoom, LatLngBounds maxBounds) {
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

  static FlutterMapState? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MapStateInheritedWidget>()
      ?.mapState;

  static FlutterMapState of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError(
          '`FlutterMapState.of()` should not be called outside a `FlutterMap` and its children'));
}

class _SafeArea {
  final LatLngBounds bounds;
  final bool isLatitudeBlocked;
  final bool isLongitudeBlocked;

  _SafeArea(LatLng southWest, LatLng northEast)
      : bounds = LatLngBounds(southWest, northEast),
        isLatitudeBlocked = southWest.latitude > northEast.latitude,
        isLongitudeBlocked = southWest.longitude > northEast.longitude;

  bool contains(LatLng point) =>
      isLatitudeBlocked || isLongitudeBlocked ? false : bounds.contains(point);

  LatLng containPoint(LatLng point, LatLng fallback) => LatLng(
        isLatitudeBlocked
            ? fallback.latitude
            : point.latitude.clamp(bounds.south, bounds.north),
        isLongitudeBlocked
            ? fallback.longitude
            : point.longitude.clamp(bounds.west, bounds.east),
      );
}
