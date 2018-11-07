import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/latlng_tween.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/core/util.dart' as util;
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';

abstract class MapGestureMixin extends State<FlutterMap>
    with TickerProviderStateMixin {
  static const double _kMinFlingVelocity = 800.0;

  LatLng _mapCenterStart;
  double _mapZoomStart;
  LatLng _focalStartGlobal;
  Point _focalStartLocal;

  LatLng _lastTapPoint;

  AnimationController _controller;
  Animation<Offset> _flingAnimation;
  Offset _flingOffset = Offset.zero;

  AnimationController _doubleTapController;
  Animation _doubleTapZoomAnimation;
  Animation _doubleTapCenterAnimation;

  FlutterMap get widget;
  MapState get mapState;
  MapState get map => mapState;
  MapOptions get options;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation);
    _doubleTapController = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 200))
      ..addListener(_handleDoubleTapZoomAnimation);
  }

  void handleScaleStart(ScaleStartDetails details) {
    setState(() {
      _mapZoomStart = map.zoom;
      _mapCenterStart = map.center;

      // determine the focal point within the widget
      final focalOffset = details.focalPoint - _mapOffset;
      _focalStartLocal = _offsetToPoint(focalOffset);
      _focalStartGlobal = _offsetToCrs(focalOffset);

      _controller.stop();
    });
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      final focalOffset = _offsetToPoint(details.focalPoint - _mapOffset);
      final newZoom = _getZoomForScale(_mapZoomStart, details.scale);
      final focalStartPt = map.project(_focalStartGlobal, newZoom);
      final newCenterPt = focalStartPt - focalOffset + map.size / 2.0;
      final newCenter = map.unproject(newCenterPt, newZoom);
      map.move(newCenter, newZoom);
      _flingOffset = _pointToOffset(_focalStartLocal - focalOffset);
    });
  }

  void handleScaleEnd(ScaleEndDetails details) {
    final double magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity) return;
    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    final double distance = (Offset.zero & context.size).shortestSide;
    _flingAnimation = new Tween<Offset>(
      begin: _flingOffset,
      end: _flingOffset - direction * distance,
    ).animate(_controller);
    _controller
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  void handleTapUp(TapUpDetails details) {

    // Get the widget's offset
    var renderObject = context.findRenderObject() as RenderBox;
    var boxOffset = renderObject.localToGlobal(Offset.zero);
    var width = renderObject.size.width;
    var height = renderObject.size.height;

    // convert the point to global coordinates
    _lastTapPoint =
        map.offsetToLatLng(details.globalPosition, boxOffset, width, height);
  }

  void handleTap(TapPosition position) {
    if (options.onTap == null) {
      return;
    }
    final latlng = _offsetToCrs(position.relative);
    // emit the event
    options.onTap(latlng);
  }

  LatLng _offsetToCrs(Offset offset) {
    // Get the widget's offset
    var renderObject = context.findRenderObject() as RenderBox;
    var width = renderObject.size.width;
    var height = renderObject.size.height;

    // convert the point to global coordinates
    var localPoint = _offsetToPoint(offset);
    var localPointCenterDistance =
        new Point((width / 2) - localPoint.x, (height / 2) - localPoint.y);
    var mapCenter = map.project(map.center);
    var point = mapCenter - localPointCenterDistance;
    return map.unproject(point);
  }

  void handleDoubleTap(TapPosition tapPosition) {
    final centerPos = _pointToOffset(map.size) / 2.0;
    final newZoom = _getZoomForScale(map.zoom, 2.0);
    final focalDelta = _getDoubleTapFocalDelta(
        centerPos, tapPosition.relative, newZoom - map.zoom);
    final newCenter = _offsetToCrs(centerPos + focalDelta);
    _startDoubleTapAnimation(newZoom, newCenter);
  }

  Offset _getDoubleTapFocalDelta(
      Offset centerPos, Offset tapPos, double zoomDiff) {
    final tapDelta = tapPos - centerPos;
    final zoomScale = 1 / math.pow(2, zoomDiff);
    // map center offset within which double-tap won't
    // cause zooming to previously invisible area
    final maxDelta = centerPos * (1 - zoomScale);
    final tappedOutExtent =
        tapDelta.dx.abs() > maxDelta.dx || tapDelta.dy.abs() > maxDelta.dy;
    return tappedOutExtent
        ? _projectDeltaOnBounds(tapDelta, maxDelta)
        : tapDelta;
  }

  Offset _projectDeltaOnBounds(Offset delta, Offset maxDelta) {
    final weightX = delta.dx.abs() / maxDelta.dx;
    final weightY = delta.dy.abs() / maxDelta.dy;
    return delta / math.max(weightX, weightY);
  }

  void _startDoubleTapAnimation(double newZoom, LatLng newCenter) {
    _doubleTapZoomAnimation = Tween<double>(begin: map.zoom, end: newZoom)
        .chain(CurveTween(curve: Curves.fastOutSlowIn))
        .animate(_doubleTapController);
    _doubleTapCenterAnimation = LatLngTween(begin: map.center, end: newCenter)
        .chain(CurveTween(curve: Curves.fastOutSlowIn))
        .animate(_doubleTapController);
    _doubleTapController
      ..value = 0.0
      ..forward();
  }

  void _handleDoubleTapZoomAnimation() {
    setState(() {
      map.move(
        _doubleTapCenterAnimation.value,
        _doubleTapZoomAnimation.value,
        hasGesture: true,
      );
    });
  }

  void _handleFlingAnimation() {
    setState(() {
      _flingOffset = _flingAnimation.value;
      var newCenterPoint = map.project(_mapCenterStart) +
          new Point(_flingOffset.dx, _flingOffset.dy);
      var newCenter = map.unproject(newCenterPoint);
      map.move(newCenter, map.zoom, hasGesture: true);
    });
  }

  Point _offsetToPoint(Offset offset) {
    return new Point(offset.dx, offset.dy);
  }

  Offset _pointToOffset(Point point) {
    return new Offset(point.x.toDouble(), point.y.toDouble());
  }

  /// Returns a map of the layer and the element touched.
  Map _elementHitTest(LatLng point) {
    var offset = map.latlngToOffset(point);
    var tap = Rect.fromCircle(center: offset, radius: 10.0);
    for (var layer in widget.layers.reversed) {
      if (layer is PolygonLayerOptions) {
        var polygon = _polygonHitTest(tap, layer);
        if (polygon != null) return {layer: polygon};
      } else if (layer is PolylineLayerOptions) {
        var polyline = _polylineHitTest(tap, layer);
        if (polyline != null) return {layer: polyline};
      } else if (layer is CircleLayerOptions) {
        var circle = _circleHitTest(tap, layer);
        if (circle != null) return {layer: circle};
      }
    }
    return null;
  }

  /// Returns the first and top-most [Polygon] that overlaps with
  /// tapped [location].
  ///
  /// Returns null if no polygon was touched.
  Polygon _polygonHitTest(Rect tap, PolygonLayerOptions layer) {
    for (var polygon in layer.polygons.reversed) {
      if (tap.overlaps(polygon.bounds)) {
        for (var i = 0; i < polygon.offsets.length - 1; i++) {
          if (util.intersects(polygon.offsets[i], polygon.offsets[i + 1], tap)) {
            return polygon;
          }
        }
      }
    }
    return null;
  }

  /// Returns the first and top-most [Polyline] that overlaps with
  /// tapped [location].
  ///
  /// Returns null if no polyline was touched.
  Polyline _polylineHitTest(Rect tap, PolylineLayerOptions layer) {
    for (var polyline in layer.polylines.reversed) {
      if (tap.overlaps(polyline.bounds)) {
        for (var i = 0; i < polyline.offsets.length - 1; i++) {
          if (util.intersects(polyline.offsets[i], polyline.offsets[i + 1], tap)) {
            return polyline;
          }
        }
      }
    }
    return null;
  }

  /// Returns the first and top-most [Circle] that overlaps with
  /// tapped [location].
  ///
  /// Returns null if no Circle was touched.
  CircleMarker _circleHitTest(Rect tap, CircleLayerOptions layer) {
    for (var circle in layer.circles.reversed) {
      if (tap.overlaps(Rect.fromCircle(center: circle.offset, radius: circle.radius))) {
        return circle;
      }
    }
    return null;
  }

  Offset get _mapOffset =>
      (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);

  double _getZoomForScale(double startZoom, double scale) =>
      startZoom + math.log(scale) / math.ln2;

  @override
  void dispose() {
    _controller.dispose();
    _doubleTapController.dispose();
    super.dispose();
  }
}
