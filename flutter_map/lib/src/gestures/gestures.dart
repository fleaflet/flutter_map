import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

abstract class MapGestureMixin extends State<FlutterMap>
    with SingleTickerProviderStateMixin {
  static const double _kMinFlingVelocity = 800.0;

  LatLng _mapCenterStart;
  double _mapZoomStart;
  Point _focalPointStart;

  AnimationController _controller;
  Animation<Offset> _flingAnimation;
  Offset _animationOffset = Offset.zero;

  FlutterMap get widget;
  MapState get mapState;
  MapState get map => mapState;
  MapOptions get options;

  void initState() {
    super.initState();
    _controller = new AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation);
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

      //Abide to min/max zoom
      var newZoom = _mapZoomStart * dScale;
      if (options.maxZoom != null)
        newZoom = (newZoom > options.maxZoom) ? options.maxZoom : newZoom;
      if (options.minZoom != null)
        newZoom = (newZoom < options.minZoom) ? options.minZoom : newZoom;

      map.move(map.unproject(newCenter), newZoom);
    });
  }

  void handleScaleEnd(ScaleEndDetails details) {
    final double magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity) return;
    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    final double distance = (Offset.zero & context.size).shortestSide;
    _flingAnimation = new Tween<Offset>(
            begin: _animationOffset,
            end: _animationOffset - direction * distance)
        .animate(_controller);
    _controller
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  void handleTapUp(TapUpDetails details) {
    if (options.onTap == null) {
      return;
    }
    // Get the widget's offset
    var renderObject = context.findRenderObject() as RenderBox;
    var boxOffset = renderObject.localToGlobal(Offset.zero);
    var width = renderObject.size.width;
    var height = renderObject.size.height;

    // convert the point to global coordinates
    var localPoint = _offsetToPoint(details.globalPosition - boxOffset);
    var localPointCenterDistance =
        new Point((width / 2) - localPoint.x, (height / 2) - localPoint.y);
    var mapCenter = map.project(map.center);
    var point = mapCenter - localPointCenterDistance;
    var latlng = map.unproject(point);

    // emit the event
    options.onTap(latlng);
  }

  void _handleFlingAnimation() {
    setState(() {
      _animationOffset = _flingAnimation.value;
      var newCenterPoint = map.project(_mapCenterStart) +
          new Point(_animationOffset.dx, _animationOffset.dy);
      var newCenter = map.unproject(newCenterPoint);
      map.move(newCenter, map.zoom);
    });
  }

  Point _offsetToPoint(Offset offset) {
    return new Point(offset.dx, offset.dy);
  }

  Offset _pointToOffset(Point point) {
    return new Offset(point.x.toDouble(), point.y.toDouble());
  }
}
