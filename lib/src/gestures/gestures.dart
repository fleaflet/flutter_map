import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/latlng_tween.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';
import 'package:vector_math/vector_math_64.dart';

abstract class MapGestureMixin extends State<FlutterMap>
    with TickerProviderStateMixin {
  static const double _kMinFlingVelocity = 800.0;

  LatLng _mapCenterStart;
  double _mapZoomStart;
  LatLng _focalStartGlobal;
  CustomPoint _focalStartLocal;

  AnimationController _controller;
  Animation<Offset> _flingAnimation;
  Offset _flingOffset = Offset.zero;

  AnimationController _doubleTapController;
  Animation _doubleTapZoomAnimation;
  Animation _doubleTapCenterAnimation;

  int _tapUpCounter = 0;
  Timer _doubleTapHoldMaxDelay;

  @override
  FlutterMap get widget;
  MapState get mapState;
  MapState get map => mapState;
  MapOptions get options;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation);
    _doubleTapController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200))
          ..addListener(_handleDoubleTapZoomAnimation);
  }

  void handleScaleStart(ScaleStartDetails details) {
    setState(() {
      _mapZoomStart = map.zoom;
      _mapCenterStart = map.center;

      // determine the focal point within the widget
      final focalOffset = details.localFocalPoint;
      _focalStartLocal = _offsetToPoint(focalOffset);
      _focalStartGlobal = _offsetToCrs(focalOffset);

      _controller.stop();
    });
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    if (_tapUpCounter == 1) {
      _handleDoubleTapHold(details);
      return;
    }

    setState(() {
      final focalOffset = _offsetToPoint(details.localFocalPoint);
      final newZoom = _getZoomForScale(_mapZoomStart, details.scale);
      final focalStartPt = map.project(_focalStartGlobal, newZoom);
      final newCenterPt = focalStartPt - focalOffset + map.size / 2.0;
      final newCenter = map.unproject(newCenterPt, newZoom);
      map.move(newCenter, newZoom, hasGesture: true);
      _flingOffset = _pointToOffset(_focalStartLocal - focalOffset);
    });
  }

  void handleScaleEnd(ScaleEndDetails details) {
    _resetDoubleTapHold();

    var magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity) {
      return;
    }

    var direction = details.velocity.pixelsPerSecond / magnitude;
    var distance = (Offset.zero & context.size).shortestSide;

    // correct fling direction with rotation
    var v = Matrix4.rotationZ(-degToRadian(mapState.rotation)) *
        Vector4(direction.dx, direction.dy, 0, 0);
    direction = Offset(v.x, v.y);

    _flingAnimation = Tween<Offset>(
      begin: _flingOffset,
      end: _flingOffset - direction * distance,
    ).animate(_controller);

    _controller
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  void handleTap(TapPosition position) {
    if (options.onTap == null) {
      return;
    }
    final latlng = _offsetToCrs(position.relative);
    // emit the event
    options.onTap(latlng);
  }

  void handleLongPress(TapPosition position) {
    _resetDoubleTapHold();

    if (options.onLongPress == null) {
      return;
    }
    final latlng = _offsetToCrs(position.relative);
    // emit the event
    options.onLongPress(latlng);
  }

  LatLng _offsetToCrs(Offset offset) {
    // Get the widget's offset
    var renderObject = context.findRenderObject() as RenderBox;
    var width = renderObject.size.width;
    var height = renderObject.size.height;

    // convert the point to global coordinates
    var localPoint = _offsetToPoint(offset);
    var localPointCenterDistance =
        CustomPoint((width / 2) - localPoint.x, (height / 2) - localPoint.y);
    var mapCenter = map.project(map.center);
    var point = mapCenter - localPointCenterDistance;
    return map.unproject(point);
  }

  void handleDoubleTap(TapPosition tapPosition) {
    _resetDoubleTapHold();

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

  void handleOnTapUp(TapUpDetails details) {
    _doubleTapHoldMaxDelay?.cancel();

    if (++_tapUpCounter == 1) {
      _doubleTapHoldMaxDelay =
          Timer(const Duration(milliseconds: 350), _resetDoubleTapHold);
    }
  }

  void _handleDoubleTapHold(ScaleUpdateDetails details) {
    _doubleTapHoldMaxDelay?.cancel();

    setState(() {
      final zoom = map.zoom;
      final focalOffset = _offsetToPoint(details.localFocalPoint);
      final verticalOffset = _pointToOffset(_focalStartLocal - focalOffset).dy;
      final newZoom = _mapZoomStart - verticalOffset / 360 * zoom;
      final min = options.minZoom ?? 0.0;
      final max = options.maxZoom ?? double.infinity;
      final actualZoom = math.max(min, math.min(max, newZoom));

      map.move(map.center, actualZoom, hasGesture: true);
    });
  }

  void _resetDoubleTapHold() {
    _doubleTapHoldMaxDelay?.cancel();
    _tapUpCounter = 0;
  }

  void _handleFlingAnimation() {
    _flingOffset = _flingAnimation.value;
    var newCenterPoint = map.project(_mapCenterStart) +
        CustomPoint(_flingOffset.dx, _flingOffset.dy);
    var newCenter = map.unproject(newCenterPoint);
    map.move(newCenter, map.zoom, hasGesture: true);
  }

  CustomPoint _offsetToPoint(Offset offset) {
    return CustomPoint(offset.dx, offset.dy);
  }

  Offset _pointToOffset(CustomPoint point) {
    return Offset(point.x.toDouble(), point.y.toDouble());
  }

  double _getZoomForScale(double startZoom, double scale) {
    var resultZoom = startZoom + math.log(scale) / math.ln2;

    return map.fitZoomToBounds(resultZoom);
  }

  @override
  void dispose() {
    _controller.dispose();
    _doubleTapController.dispose();
    super.dispose();
  }
}
