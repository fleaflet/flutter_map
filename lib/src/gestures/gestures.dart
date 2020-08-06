import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/interactive_flags.dart';
import 'package:flutter_map/src/gestures/latlng_tween.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';
import 'package:vector_math/vector_math_64.dart';

abstract class MapGestureMixin extends State<FlutterMap>
    with TickerProviderStateMixin {
  static const double _kMinFlingVelocity = 800.0;

  double _lastRotation = 0.0;
  double _rotationAccumlator = 0.0;
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
  MapState get map => mapState;
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
    if (!InteractiveFlags.hasFlag(flags, InteractiveFlags.fling)) {
      closeFlingController(MapEventSource.interactiveFlagsChanged);
    }
    if (!InteractiveFlags.hasFlag(flags, InteractiveFlags.doubleTapZoom)) {
      closeDoubleTapController(MapEventSource.interactiveFlagsChanged);
    }

    if (_rotationStarted &&
        !InteractiveFlags.hasFlag(flags, InteractiveFlags.rotate)) {
      _rotationStarted = false;
      map.emitMapEvent(
        MapEventRotateEnd(
          center: map.center,
          zoom: map.zoom,
          source: MapEventSource.dragStart,
        ),
      );
    }
  }

  void closeFlingController(MapEventSource source) {
    if (_flingController.isAnimating) {
      _flingController.stop();

      map.emitMapEvent(
        MapEventFlingEnd(center: map.center, zoom: map.zoom, source: source),
      );
    }
  }

  void closeDoubleTapController(MapEventSource source) {
    if (_doubleTapController.isAnimating) {
      _doubleTapController.stop();

      map.emitMapEvent(
        MapEventDoubleTapZoomEnd(
            center: map.center, zoom: map.zoom, source: source),
      );
    }
  }

  void handleScaleStart(ScaleStartDetails details) {
    closeFlingController(MapEventSource.dragStart);
    closeDoubleTapController(MapEventSource.dragStart);

    _mapZoomStart = map.zoom;
    _mapCenterStart = map.center;

    _rotationStarted = false;
    _lastRotation = 0.0;
    _rotationAccumlator = 0.0;

    // determine the focal point within the widget
    final focalOffset = details.localFocalPoint;
    _focalStartLocal = _offsetToPoint(focalOffset);
    _focalStartGlobal = _offsetToCrs(focalOffset);

    var flags = options.interactiveFlags;
    if (InteractiveFlags.hasFlag(flags, InteractiveFlags.move)) {
      map.emitMapEvent(
        MapEventMoveStart(
          center: map.center,
          zoom: map.zoom,
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
    var hasMove = InteractiveFlags.hasFlag(flags, InteractiveFlags.move);
    var hasPinchZoom =
        InteractiveFlags.hasFlag(flags, InteractiveFlags.pinchZoom);
    var hasRotate = InteractiveFlags.hasFlag(flags, InteractiveFlags.rotate);

    final focalOffset = _offsetToPoint(details.localFocalPoint);
    _flingOffset = _pointToOffset(_focalStartLocal - focalOffset);

    var mapMoved = false;
    if (hasMove || hasPinchZoom) {
      final newZoom = hasPinchZoom
          ? _getZoomForScale(_mapZoomStart, details.scale)
          : map.zoom;
      LatLng newCenter;
      if (hasMove) {
        final focalStartPt = map.project(_focalStartGlobal, newZoom);
        final newCenterPt = focalStartPt - focalOffset + map.size / 2.0;
        newCenter = map.unproject(newCenterPt, newZoom);
      } else {
        newCenter = map.center;
      }
      mapMoved = map.move(
        newCenter,
        newZoom,
        hasGesture: true,
        source: MapEventSource.onDrag,
      );
    }

    var newRotation = radianToDeg(details.rotation);
    var rotationDiff = newRotation - _lastRotation;
    _rotationAccumlator += rotationDiff;
    _lastRotation = newRotation;

    if (hasRotate) {
      if (!_rotationStarted &&
          _rotationAccumlator.abs() >= options.rotationThreshold) {
        _rotationStarted = true;
        map.emitMapEvent(
          MapEventRotateStart(
            center: map.center,
            zoom: map.zoom,
            source: MapEventSource.dragStart,
          ),
        );
      }

      if (_rotationStarted) {
        map.rotate(
          map.rotation + rotationDiff,
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
        InteractiveFlags.hasFlag(
            options.interactiveFlags, InteractiveFlags.rotate)) {
      _rotationStarted = false;
      map.emitMapEvent(
        MapEventRotateEnd(
          center: map.center,
          zoom: map.zoom,
          source: MapEventSource.dragStart,
        ),
      );
    }

    if (InteractiveFlags.hasFlag(
        options.interactiveFlags, InteractiveFlags.move)) {
      map.emitMapEvent(
        MapEventMoveEnd(
          center: map.center,
          zoom: map.zoom,
          source: MapEventSource.dragEnd,
        ),
      );
    }

    var hasFling = InteractiveFlags.hasFlag(
        options.interactiveFlags, InteractiveFlags.fling);
    var magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity || !hasFling) {
      if (hasFling) {
        map.emitMapEvent(
          MapEventFlingNotStarted(
            center: map.center,
            zoom: map.zoom,
            source: MapEventSource.dragEnd,
          ),
        );
      }

      return;
    }

    var direction = details.velocity.pixelsPerSecond / magnitude;
    var distance = (Offset.zero & context.size).shortestSide;

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

    final latlng = _offsetToCrs(position.relative);
    if (options.onTap != null) {
      // emit the event
      options.onTap(latlng);
    }

    map.emitMapEvent(
      MapEventTap(
        tapPosition: latlng,
        center: map.center,
        zoom: map.zoom,
        source: MapEventSource.tap,
      ),
    );
  }

  void handleLongPress(TapPosition position) {
    _resetDoubleTapHold();

    closeFlingController(MapEventSource.longPress);
    closeDoubleTapController(MapEventSource.longPress);

    final latlng = _offsetToCrs(position.relative);
    if (options.onLongPress != null) {
      // emit the event
      options.onLongPress(latlng);
    }

    map.emitMapEvent(
      MapEventLongPress(
        tapPosition: latlng,
        center: map.center,
        zoom: map.zoom,
        source: MapEventSource.longPress,
      ),
    );
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

    closeFlingController(MapEventSource.doubleTap);
    closeDoubleTapController(MapEventSource.doubleTap);

    if (InteractiveFlags.hasFlag(
        options.interactiveFlags, InteractiveFlags.doubleTapZoom)) {
      final centerPos = _pointToOffset(map.size) / 2.0;
      final newZoom = _getZoomForScale(map.zoom, 2.0);
      final focalDelta = _getDoubleTapFocalDelta(
          centerPos, tapPosition.relative, newZoom - map.zoom);
      final newCenter = _offsetToCrs(centerPos + focalDelta);
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
    _doubleTapZoomAnimation = Tween<double>(begin: map.zoom, end: newZoom)
        .chain(CurveTween(curve: Curves.fastOutSlowIn))
        .animate(_doubleTapController);
    _doubleTapCenterAnimation = LatLngTween(begin: map.center, end: newCenter)
        .chain(CurveTween(curve: Curves.fastOutSlowIn))
        .animate(_doubleTapController);
    _doubleTapController.forward(from: 0.0);
  }

  void _doubleTapZoomStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      map.emitMapEvent(
        MapEventDoubleTapZoomStart(
            center: map.center,
            zoom: map.zoom,
            source: MapEventSource.doubleTapZoomAnimationController),
      );
    } else if (status == AnimationStatus.completed) {
      map.emitMapEvent(
        MapEventDoubleTapZoomEnd(
            center: map.center,
            zoom: map.zoom,
            source: MapEventSource.doubleTapZoomAnimationController),
      );
    }
  }

  void _handleDoubleTapZoomAnimation() {
    map.move(
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
    if (InteractiveFlags.hasFlag(flags, InteractiveFlags.pinchZoom)) {
      final zoom = map.zoom;
      final focalOffset = _offsetToPoint(details.localFocalPoint);
      final verticalOffset = _pointToOffset(_focalStartLocal - focalOffset).dy;
      final newZoom = _mapZoomStart - verticalOffset / 360 * zoom;
      final min = options.minZoom ?? 0.0;
      final max = options.maxZoom ?? double.infinity;
      final actualZoom = math.max(min, math.min(max, newZoom));

      map.move(
        map.center,
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
      map.emitMapEvent(
        MapEventFlingStart(
            center: map.center,
            zoom: map.zoom,
            source: MapEventSource.flingAnimationController),
      );
    } else if (status == AnimationStatus.completed) {
      map.emitMapEvent(
        MapEventFlingEnd(
            center: map.center,
            zoom: map.zoom,
            source: MapEventSource.flingAnimationController),
      );
    }
  }

  void _handleFlingAnimation() {
    _flingOffset = _flingAnimation.value;
    var newCenterPoint = map.project(_mapCenterStart) +
        CustomPoint(_flingOffset.dx, _flingOffset.dy);
    var newCenter = map.unproject(newCenterPoint);
    map.move(
      newCenter,
      map.zoom,
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

    return map.fitZoomToBounds(resultZoom);
  }

  @override
  void dispose() {
    _flingController.dispose();
    _doubleTapController.dispose();
    super.dispose();
  }
}
