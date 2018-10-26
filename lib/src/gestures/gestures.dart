import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/core/location_utils.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

abstract class MapGestureMixin extends State<FlutterMap>
    with TickerProviderStateMixin {
  static const double _kMinFlingVelocity = 800.0;

  LatLng _mapCenterStart;
  double _mapZoomStart;
  Point _focalPointStart;

  AnimationController _controller;
  Animation<Offset> _flingAnimation;
  Offset _animationOffset = Offset.zero;

  AnimationController _doubleTapController;
  Animation _doubleTapAnimation;

  FlutterMap get widget;
  MapState get mapState;
  MapState get map => mapState;
  MapOptions get options;

  LatLng _latlng;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation);
    _doubleTapController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 200))
      ..addListener(_handleDoubleTapZoomAnimation);
  }

  void handleScaleStart(ScaleStartDetails details) {
    setState(() {
      _mapZoomStart = map.zoom;
      _mapCenterStart = map.center;

      // Get the widget's offset
      var renderObject = context.findRenderObject() as RenderBox;
      var boxOffset = renderObject.localToGlobal(Offset.zero);

      // determine the focal point within the widget
      var localFocalPoint = _offsetToPoint(details.focalPoint - boxOffset);
      _focalPointStart = localFocalPoint;

      _controller.stop();
    });
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      var dScale = details.scale;
      for (var i = 0; i < 2; i++) {
        dScale = math.sqrt(dScale);
      }
      var renderObject = context.findRenderObject() as RenderBox;
      var boxOffset = renderObject.localToGlobal(Offset.zero);

      // Draw the focal point
      var localFocalPoint = _offsetToPoint(details.focalPoint - boxOffset);

      // get the focal point in global coordinates
      var dFocalPoint = localFocalPoint - _focalPointStart;

      var focalCenterDistance = localFocalPoint - (map.size / 2);
      var newCenter = map.project(_mapCenterStart) +
          focalCenterDistance.multiplyBy(1 - 1 / dScale) -
          dFocalPoint;

      var offsetPt = newCenter - map.project(_mapCenterStart);
      _animationOffset = _pointToOffset(offsetPt);

      var newZoom = _mapZoomStart * dScale;
      map.move(map.unproject(newCenter), newZoom);
    });
  }

  void handleScaleEnd(ScaleEndDetails details) {
    final double magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity) return;
    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    final double distance = (Offset.zero & context.size).shortestSide;
    _flingAnimation = Tween<Offset>(
            begin: _animationOffset,
            end: _animationOffset - direction * distance)
        .animate(_controller);
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
    _latlng =
        map.offsetToLatLng(details.globalPosition, boxOffset, width, height);
  }

  void handleTap() {
    if (_latlng == null) {
      return;
    }
    var map = _getElementTouched();
    if (map != null) {
      var layer = map.keys.first;
      if (layer.onTap != null) {
        layer.onTap(map[layer], _latlng);
      }
    } else if (options.onTap != null) options.onTap(_latlng);
  }

  void handleLongPress() {
    if (_latlng == null) {
      return;
    }
    var map = _getElementTouched();
    if (map != null) {
      var layer = map.keys.first;
      if (layer.onTap != null) {
        layer.onLongPress(map[layer], _latlng);
      }
    } else if (options.onLongPress != null) options.onLongPress(_latlng);
  }

  /// Returns a map of the layer and the element toched.
  Map _getElementTouched() {
    for (var layer in widget.layers.reversed) {
      if (layer is PolygonLayerOptions) {
        var polygon = _getPolygonByLocation(layer);
        if (polygon != null) return {layer: polygon};
      } else if (layer is PolylineLayerOptions) {
        var polyline = _getPolylineByLocation(layer);
        if (polyline != null) return {layer: polyline};
      } else if (layer is CircleLayerOptions) {
        var circle = _getCircleByLocation(layer);
        if (circle != null) return {layer: circle};
      }
    }
    return null;
  }

  /// Returns the polygon that contains the [location] and
  /// is on top of the other polygons.
  ///
  /// Returns null if no polygon was touched.
  Polygon _getPolygonByLocation(PolygonLayerOptions layer) {
    for (var polygon in layer.polygons.reversed) {
      if (LocationUtils.containsLocation(
          _latlng.latitude, _latlng.longitude, polygon.points)) {
        return polygon;
      }
    }
    return null;
  }

  /// Returns the polyline that contains the [location] in its path and
  /// is on top of the other polylines.
  ///
  /// Returns null if no polyline was touched.
  Polyline _getPolylineByLocation(PolylineLayerOptions layer) {
    for (var polyline in layer.polylines.reversed) {
      ///Calculates an amount of meters of tolerance for the line
      ///considering the width. When zoomed out is more dificul to tap on
      ///the line so this distance helps compensate using the width and
      ///the meters per pixel for the current zoom level. In conclusion,
      ///a thicker line will be easier to tap.
      var meters = map.getMetersPerPixel(_latlng.latitude) *
          (polyline.strokeWidth * 0.5);
      if (LocationUtils.isPointInPolyline(_latlng, polyline.points,
          toleratedDistance: meters)) {
        return polyline;
      }
    }
    return null;
  }

  /// Returns the Circle that contains the [location].
  ///
  /// Returns null if no Circle was touched.
  CircleMarker _getCircleByLocation(CircleLayerOptions layer) {
    for (var circle in layer.circles.reversed) {
      Circle c = Circle(circle.center, circle.radius);
      if (c.isPointInside(_latlng)) {
        return circle;
      }
    }
    return null;
  }

  void handleDoubleTap() {
    ///Currently zooms in the center of the screen
    ///TODO: change the newCenter to be where the user tapped, see https://github.com/flutter/flutter/issues/10048

    _mapZoomStart = map.zoom;
    _mapCenterStart = map.center;

    double dScale = 2.0;
    for (var i = 0; i < 2; i++) {
      dScale = math.sqrt(dScale);
    }

    double newZoom = _mapZoomStart * dScale;

    _doubleTapAnimation = Tween<double>(
      begin: _mapZoomStart,
      end: newZoom,
    )
        .chain(CurveTween(curve: Curves.fastOutSlowIn))
        .animate(_doubleTapController);
    _doubleTapController
      ..value = 0.0
      ..forward();
  }

  void _handleDoubleTapZoomAnimation() {
    var newCenter = map.project(_mapCenterStart);
    setState(() {
      map.move(map.unproject(newCenter), _doubleTapAnimation.value);
    });
  }

  void _handleFlingAnimation() {
    setState(() {
      _animationOffset = _flingAnimation.value;
      var newCenterPoint = map.project(_mapCenterStart) +
          Point(_animationOffset.dx, _animationOffset.dy);
      var newCenter = map.unproject(newCenterPoint);
      map.move(newCenter, map.zoom);
    });
  }

  Point _offsetToPoint(Offset offset) {
    return Point(offset.dx, offset.dy);
  }

  Offset _pointToOffset(Point point) {
    return Offset(point.x.toDouble(), point.y.toDouble());
  }

  @override
  void dispose() {
    _controller.dispose();
    _doubleTapController.dispose();
    super.dispose();
  }
}
