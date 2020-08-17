import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/interactive_flag.dart';
import 'package:flutter_map/src/gestures/latlng_tween.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';
import 'package:vector_math/vector_math_64.dart';

abstract class MapGestureMixin extends State<FlutterMap>
    with TickerProviderStateMixin {
  static const double _kMinFlingVelocity = 800.0;

  double _lastRotation = 0.0;
  double _rotationAccumulator = 0.0;
  bool _rotationStarted = false;

  LatLng _mapCenterStart;
  double _mapZoomStart;
  LatLng _focalStartGlobal;
  CustomPoint _focalStartLocal;

  AnimationController _flingController;
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
  MapOptions get options;

  @override
  void initState() {
    super.initState();
    _flingController = AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation)
      ..addStatusListener(_flingAnimationStatusListener);
    _doubleTapController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200))
          ..addListener(_handleDoubleTapZoomAnimation)
          ..addStatusListener(_doubleTapZoomStatusListener);
  }

  @override
  void didUpdateWidget(FlutterMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    var flags = options.interactiveFlags;
    if (!InteractiveFlag.hasFlag(flags, InteractiveFlag.fling)) {
      closeFlingController(MapEventSource.interactiveFlagsChanged);
    }
    if (!InteractiveFlag.hasFlag(flags, InteractiveFlag.doubleTapZoom)) {
      closeDoubleTapController(MapEventSource.interactiveFlagsChanged);
    }

    if (_rotationStarted &&
        !InteractiveFlag.hasFlag(flags, InteractiveFlag.rotate)) {
      _rotationStarted = false;
      mapState.emitMapEvent(
        MapEventRotateEnd(
          center: mapState.center,
          zoom: mapState.zoom,
          source: MapEventSource.interactiveFlagsChanged,
        ),
      );
    }
  }

  void closeFlingController(MapEventSource source) {
    if (_flingController.isAnimating) {
      _flingController.stop();

      mapState.emitMapEvent(
        MapEventFlingEnd(
            center: mapState.center, zoom: mapState.zoom, source: source),
      );
    }
  }

  void closeDoubleTapController(MapEventSource source) {
    if (_doubleTapController.isAnimating) {
      _doubleTapController.stop();

      mapState.emitMapEvent(
        MapEventDoubleTapZoomEnd(
            center: mapState.center, zoom: mapState.zoom, source: source),
      );
    }
  }

  void handleScaleStart(ScaleStartDetails details) {
    closeFlingController(MapEventSource.dragStart);
    closeDoubleTapController(MapEventSource.dragStart);

    _mapZoomStart = mapState.zoom;
    _mapCenterStart = mapState.center;

    _rotationStarted = false;
    _lastRotation = 0.0;
    _rotationAccumulator = 0.0;

    // determine the focal point within the widget
    final focalOffset = details.localFocalPoint;
    _focalStartLocal = _offsetToPoint(focalOffset);
    _focalStartGlobal = _offsetToCrs(focalOffset, false);

    var flags = options.interactiveFlags;
    if (InteractiveFlag.hasFlag(flags, InteractiveFlag.move)) {
      mapState.emitMapEvent(
        MapEventMoveStart(
          center: mapState.center,
          zoom: mapState.zoom,
          source: MapEventSource.dragStart,
        ),
      );
    }
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    if (_tapUpCounter == 1) {
      _handleDoubleTapHold(details);
      return;
    }

    var flags = options.interactiveFlags;
    var hasMove = InteractiveFlag.hasFlag(flags, InteractiveFlag.move);
    var hasPinchZoom =
        InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchZoom);
    var hasRotate = InteractiveFlag.hasFlag(flags, InteractiveFlag.rotate);

    final focalOffset = _offsetToPoint(details.localFocalPoint);
    _flingOffset = _pointToOffset(_focalStartLocal - focalOffset);

    var mapMoved = false;
    if (hasMove || hasPinchZoom) {
      final newZoom = hasPinchZoom
          ? _getZoomForScale(_mapZoomStart, details.scale)
          : mapState.zoom;
      LatLng newCenter;
      if (hasMove) {
        final focalStartPt = mapState.project(_focalStartGlobal, newZoom);
        final newCenterPt = focalStartPt - focalOffset + mapState.size / 2.0;
        newCenter = mapState.unproject(newCenterPt, newZoom);
      } else {
        newCenter = mapState.center;
      }
      mapMoved = mapState.move(
        newCenter,
        newZoom,
        hasGesture: true,
        source: MapEventSource.onDrag,
      );
    }

    var newRotation = radianToDeg(details.rotation);
    var rotationDiff = newRotation - _lastRotation;
    _rotationAccumulator += rotationDiff;
    _lastRotation = newRotation;

    if (hasRotate) {
      if (!_rotationStarted &&
          _rotationAccumulator.abs() >= options.rotationThreshold) {
        _rotationStarted = true;
        mapState.emitMapEvent(
          MapEventRotateStart(
            center: mapState.center,
            zoom: mapState.zoom,
            source: MapEventSource.onDrag,
          ),
        );
      }

      if (_rotationStarted) {
        mapState.rotate(
          mapState.rotation + rotationDiff,
          hasGesture: true,
          simulateMove: !mapMoved,
          source: MapEventSource.onDrag,
        );
      }
    }
  }

  void handleScaleEnd(ScaleEndDetails details) {
    _resetDoubleTapHold();

    if (_rotationStarted &&
        InteractiveFlag.hasFlag(
            options.interactiveFlags, InteractiveFlag.rotate)) {
      _rotationStarted = false;
      mapState.emitMapEvent(
        MapEventRotateEnd(
          center: mapState.center,
          zoom: mapState.zoom,
          source: MapEventSource.dragEnd,
        ),
      );
    }

    if (InteractiveFlag.hasFlag(
        options.interactiveFlags, InteractiveFlag.move)) {
      mapState.emitMapEvent(
        MapEventMoveEnd(
          center: mapState.center,
          zoom: mapState.zoom,
          source: MapEventSource.dragEnd,
        ),
      );
    }

    var hasFling = InteractiveFlag.hasFlag(
        options.interactiveFlags, InteractiveFlag.fling);
    var magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity || !hasFling) {
      if (hasFling) {
        mapState.emitMapEvent(
          MapEventFlingNotStarted(
            center: mapState.center,
            zoom: mapState.zoom,
            source: MapEventSource.dragEnd,
          ),
        );
      }

      return;
    }

    var direction = details.velocity.pixelsPerSecond / magnitude;
    var distance =
        (Offset.zero & Size(mapState.size.x, mapState.size.y)).shortestSide;

    if (mapState.rotation != 0.0) {
      // correct fling direction with rotation
      var v = Matrix4.rotationZ(-degToRadian(mapState.rotation)) *
          Vector4(direction.dx, direction.dy, 0, 0);
      direction = Offset(v.x, v.y);
    }

    _flingAnimation = Tween<Offset>(
      begin: _flingOffset,
      end: _flingOffset - direction * distance,
    ).animate(_flingController);

    _flingController
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  void handleTap(TapPosition position) {
    closeFlingController(MapEventSource.tap);
    closeDoubleTapController(MapEventSource.tap);

    final latlng = _offsetToCrs(position.relative, true);
    if (options.onTap != null) {
      // emit the event
      options.onTap(latlng);
    }

    mapState.emitMapEvent(
      MapEventTap(
        tapPosition: latlng,
        center: mapState.center,
        zoom: mapState.zoom,
        source: MapEventSource.tap,
      ),
    );
  }

  void handleLongPress(TapPosition position) {
    _resetDoubleTapHold();

    closeFlingController(MapEventSource.longPress);
    closeDoubleTapController(MapEventSource.longPress);

    final latlng = _offsetToCrs(position.relative, true);
    if (options.onLongPress != null) {
      // emit the event
      options.onLongPress(latlng);
    }

    mapState.emitMapEvent(
      MapEventLongPress(
        tapPosition: latlng,
        center: mapState.center,
        zoom: mapState.zoom,
        source: MapEventSource.longPress,
      ),
    );
  }

  LatLng _offsetToCrs(Offset offset, bool correctOffsetWithRotation) {
    var width = mapState.size.x;
    var height = mapState.size.y;

    if (correctOffsetWithRotation && mapState.rotation != 0.0) {
      // correct offset with rotation
      var v = Matrix4.rotationZ(-degToRadian(mapState.rotation)) *
          Vector4(offset.dx, offset.dy, 0, 0);
      offset = Offset(v.x, v.y);
    }

    // convert the point to global coordinates
    var localPoint = _offsetToPoint(offset);
    var localPointCenterDistance =
        CustomPoint((width / 2) - localPoint.x, (height / 2) - localPoint.y);
    var mapCenter = mapState.project(mapState.center);
    var point = mapCenter - localPointCenterDistance;
    return mapState.unproject(point);
  }

  void handleDoubleTap(TapPosition tapPosition) {
    _resetDoubleTapHold();

    closeFlingController(MapEventSource.doubleTap);
    closeDoubleTapController(MapEventSource.doubleTap);

    if (InteractiveFlag.hasFlag(
        options.interactiveFlags, InteractiveFlag.doubleTapZoom)) {
      final centerPos = _pointToOffset(mapState.size) / 2.0;
      final newZoom = _getZoomForScale(mapState.zoom, 2.0);
      final focalDelta = _getDoubleTapFocalDelta(
          centerPos, tapPosition.relative, newZoom - mapState.zoom);
      final newCenter = _offsetToCrs(centerPos + focalDelta, true);
      _startDoubleTapAnimation(newZoom, newCenter);
    }
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
    _doubleTapZoomAnimation = Tween<double>(begin: mapState.zoom, end: newZoom)
        .chain(CurveTween(curve: Curves.fastOutSlowIn))
        .animate(_doubleTapController);
    _doubleTapCenterAnimation =
        LatLngTween(begin: mapState.center, end: newCenter)
            .chain(CurveTween(curve: Curves.fastOutSlowIn))
            .animate(_doubleTapController);
    _doubleTapController.forward(from: 0.0);
  }

  void _doubleTapZoomStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      mapState.emitMapEvent(
        MapEventDoubleTapZoomStart(
            center: mapState.center,
            zoom: mapState.zoom,
            source: MapEventSource.doubleTapZoomAnimationController),
      );
    } else if (status == AnimationStatus.completed) {
      mapState.emitMapEvent(
        MapEventDoubleTapZoomEnd(
            center: mapState.center,
            zoom: mapState.zoom,
            source: MapEventSource.doubleTapZoomAnimationController),
      );
    }
  }

  void _handleDoubleTapZoomAnimation() {
    mapState.move(
      _doubleTapCenterAnimation.value,
      _doubleTapZoomAnimation.value,
      hasGesture: true,
      source: MapEventSource.doubleTapZoomAnimationController,
    );
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

    var flags = options.interactiveFlags;
    // TODO: is this pinchZoom? never seen this fired
    if (InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchZoom)) {
      final zoom = mapState.zoom;
      final focalOffset = _offsetToPoint(details.localFocalPoint);
      final verticalOffset = _pointToOffset(_focalStartLocal - focalOffset).dy;
      final newZoom = _mapZoomStart - verticalOffset / 360 * zoom;
      final min = options.minZoom ?? 0.0;
      final max = options.maxZoom ?? double.infinity;
      final actualZoom = math.max(min, math.min(max, newZoom));

      mapState.move(
        mapState.center,
        actualZoom,
        hasGesture: true,
        source: MapEventSource.doubleTapHold,
      );
    }
  }

  void _resetDoubleTapHold() {
    _doubleTapHoldMaxDelay?.cancel();
    _tapUpCounter = 0;
  }

  void _flingAnimationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      mapState.emitMapEvent(
        MapEventFlingStart(
            center: mapState.center,
            zoom: mapState.zoom,
            source: MapEventSource.flingAnimationController),
      );
    } else if (status == AnimationStatus.completed) {
      mapState.emitMapEvent(
        MapEventFlingEnd(
            center: mapState.center,
            zoom: mapState.zoom,
            source: MapEventSource.flingAnimationController),
      );
    }
  }

  void _handleFlingAnimation() {
    _flingOffset = _flingAnimation.value;
    var newCenterPoint = mapState.project(_mapCenterStart) +
        CustomPoint(_flingOffset.dx, _flingOffset.dy);
    var newCenter = mapState.unproject(newCenterPoint);
    mapState.move(
      newCenter,
      mapState.zoom,
      hasGesture: true,
      source: MapEventSource.flingAnimationController,
    );
  }

  CustomPoint _offsetToPoint(Offset offset) {
    return CustomPoint(offset.dx, offset.dy);
  }

  Offset _pointToOffset(CustomPoint point) {
    return Offset(point.x.toDouble(), point.y.toDouble());
  }

  double _getZoomForScale(double startZoom, double scale) {
    var resultZoom = startZoom + math.log(scale) / math.ln2;

    return mapState.fitZoomToBounds(resultZoom);
  }

  @override
  void dispose() {
    _flingController.dispose();
    _doubleTapController.dispose();
    super.dispose();
  }
}
