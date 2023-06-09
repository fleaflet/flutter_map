import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/interaction_detector.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:flutter_map/src/map/flutter_map_state_inherited_widget.dart';
import 'package:latlong2/latlong.dart';

class FlutterMapStateContainer extends State<FlutterMap> {
  static const invalidSize = CustomPoint<double>(-1, -1);
  final _flutterMapGestureDetectorKey = GlobalKey<InteractionDetectorState>();

  bool _hasFitInitialBounds = false;

  final _localController = MapController();
  MapController get mapController => widget.mapController ?? _localController;

  late FlutterMapState _mapState;

  FlutterMapState get mapState => _mapState;

  LatLng get center => _mapState.center;

  LatLngBounds get bounds => _mapState.bounds;

  double get zoom => _mapState.zoom;

  double get rotation => _mapState.rotation;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.options.onMapReady?.call());

    _mapState = FlutterMapState(
      options: widget.options,
      center: widget.options.center,
      zoom: widget.options.zoom,
      rotation: widget.options.rotation,
      nonrotatedSize: invalidSize,
      size: invalidSize,
      hasFitInitialBounds: _hasFitInitialBounds,
    );
  }

  @override
  void didUpdateWidget(FlutterMap oldWidget) {
    if (oldWidget.options != widget.options) {
      _mapState = _mapState.withOptions(widget.options);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _onConstraintsChange(constraints);

        return MapStateInheritedWidget(
          mapController: mapController,
          mapState: _mapState,
          child: InteractionDetector(
            key: _flutterMapGestureDetectorKey,
            options: widget.options,
            currentMapState: () => _mapState,
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            onPointerHover: _onPointerHover,
            onRotateEnd: _onRotateEnd,
            onFlingStart: _onFlingStart,
            onFlingEnd: _onFlingEnd,
            onMoveEnd: _onMoveEnd,
            onOneFingerPinchZoom: _onOneFingerPinchZoom,
            onDoubleTapZoomEnd: _onDoubleTapZoomEnd,
            onMoveStart: _onMoveStart,
            onRotateStart: _onRotateStart,
            onFlingNotStarted: _onFlingNotStarted,
            onPinchZoomUpdate: _onPinchZoomUpdate,
            onRotateUpdate: _onRotateUpdate,
            onTap: _onTap,
            onDragUpdate: _onDragUpdate,
            onSecondaryTap: _onSecondaryTap,
            onLongPress: _onLongPress,
            onDoubleTapZoomStart: _onDoubleTapZoomStart,
            onScroll: _onScroll,
            onDoubleTapZoomUpdate: _onDoubleTapZoomUpdate,
            onFlingUpdate: _onFlingUpdate,
            child: ClipRect(
              child: Stack(
                children: [
                  OverflowBox(
                    minWidth: _mapState.size.x,
                    maxWidth: _mapState.size.x,
                    minHeight: _mapState.size.y,
                    maxHeight: _mapState.size.y,
                    child: Transform.rotate(
                      angle: _mapState.rotationRad,
                      child: Stack(children: widget.children),
                    ),
                  ),
                  Stack(children: widget.nonRotatedChildren),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onDoubleTapZoomUpdate(
    MapEventSource source,
    LatLng position,
    double zoom,
  ) {
    move(
      position,
      zoom,
      hasGesture: true,
      source: source,
    );
  }

  void _onFlingUpdate(MapEventSource source, LatLng position) {
    move(
      position,
      _mapState.zoom,
      hasGesture: true,
      source: source,
    );
  }

  void _onRotateUpdate(
    MapEventSource source,
    LatLng position,
    double zoom,
    double rotation,
  ) {
    moveAndRotate(position, zoom, rotation, source: source, hasGesture: true);
  }

  void _onOneFingerPinchZoom(MapEventSource source, double newZoom) {
    final min = widget.options.minZoom ?? 0.0;
    final max = widget.options.maxZoom ?? double.infinity;
    final actualZoom = math.max(min, math.min(max, newZoom));

    move(
      _mapState.center,
      actualZoom,
      hasGesture: true,
      source: source,
    );
  }

  void _onScroll(PointerScrollEvent event) {
    final minZoom = widget.options.minZoom ?? 0.0;
    final maxZoom = widget.options.maxZoom ?? double.infinity;
    final newZoom = (_mapState.zoom -
            event.scrollDelta.dy * widget.options.scrollWheelVelocity)
        .clamp(minZoom, maxZoom);
    // Calculate offset of mouse cursor from viewport center
    final List<dynamic> newCenterZoom = _mapState.getNewEventCenterZoomPosition(
        _mapState.offsetToPoint(event.localPosition), newZoom);

    // Move to new center and zoom level
    move(
      newCenterZoom[0] as LatLng,
      newCenterZoom[1] as double,
      source: MapEventSource.scrollWheel,
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (widget.options.onPointerDown != null) {
      final latlng = _mapState.offsetToCrs(event.localPosition);
      widget.options.onPointerDown!(event, latlng);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (widget.options.onPointerUp != null) {
      final latlng = _mapState.offsetToCrs(event.localPosition);
      widget.options.onPointerUp!(event, latlng);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (widget.options.onPointerCancel != null) {
      final latlng = _mapState.offsetToCrs(event.localPosition);
      widget.options.onPointerCancel!(event, latlng);
    }
  }

  void _onPointerHover(PointerHoverEvent event) {
    if (widget.options.onPointerHover != null) {
      final latlng = _mapState.offsetToCrs(event.localPosition);
      widget.options.onPointerHover!(event, latlng);
    }
  }

  void _onTap(MapEventSource source, LatLng position) {
    _emitMapEvent(
      MapEventTap(
        tapPosition: position,
        mapState: _mapState,
        source: source,
      ),
    );
  }

  void _onSecondaryTap(MapEventSource source, LatLng position) {
    _emitMapEvent(
      MapEventSecondaryTap(
        tapPosition: position,
        mapState: _mapState,
        source: source,
      ),
    );
  }

  void _onDragUpdate(MapEventSource source, Offset offset) {
    final oldCenterPt = _mapState.project(_mapState.center);

    final newCenterPt = oldCenterPt + _mapState.offsetToPoint(offset);
    final newCenter = _mapState.unproject(newCenterPt);

    move(newCenter, _mapState.zoom, hasGesture: true, source: source);
  }

  void _onPinchZoomUpdate(MapEventSource source, LatLng position, double zoom) {
    move(position, zoom, hasGesture: true, source: source);
  }

  void _onLongPress(MapEventSource source, LatLng position) {
    _emitMapEvent(
      MapEventLongPress(
        tapPosition: position,
        mapState: _mapState,
        source: source,
      ),
    );
  }

  void _onMoveStart(MapEventSource source) {
    _emitMapEvent(
      MapEventMoveStart(
        mapState: _mapState,
        source: source,
      ),
    );
  }

  void _onRotateStart(MapEventSource source) {
    _emitMapEvent(
      MapEventRotateStart(
        mapState: _mapState,
        source: source,
      ),
    );
  }

  void _onRotateEnd(MapEventSource source) {
    _emitMapEvent(
      MapEventRotateEnd(
        mapState: _mapState,
        source: source,
      ),
    );
  }

  void _onMoveEnd(MapEventSource source) {
    _emitMapEvent(
      MapEventRotateEnd(
        mapState: _mapState,
        source: source,
      ),
    );
  }

  void _onFlingStart(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationStart(
        mapState: _mapState,
        source: MapEventSource.flingAnimationController,
      ),
    );
  }

  void _onFlingEnd(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationEnd(
        mapState: _mapState,
        source: source,
      ),
    );
  }

  void _onDoubleTapZoomEnd(MapEventSource source) {
    _emitMapEvent(
      MapEventDoubleTapZoomEnd(
        mapState: _mapState,
        source: source,
      ),
    );
  }

  void _onDoubleTapZoomStart(MapEventSource source) {
    _emitMapEvent(
      MapEventDoubleTapZoomStart(
          mapState: _mapState,
          source: MapEventSource.doubleTapZoomAnimationController),
    );
  }

  void _onFlingNotStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationNotStarted(
        mapState: _mapState,
        source: source,
      ),
    );
  }

  // No need to call setState in here as we are already running a build and the
  // resulting FlutterMapState will be passed to the inherited widget which
  // will trigger a build if it is different.
  void _onConstraintsChange(BoxConstraints constraints) {
    // Update on layout change.
    _updateAndEmitSizeIfConstraintsChanged(constraints);

    // If bounds were provided set the initial center/zoom to match those
    // bounds once the parent constraints are available.
    if (widget.options.bounds != null &&
        !_hasFitInitialBounds &&
        _parentConstraintsAreSet(context, constraints)) {
      final target = _mapState.getBoundsCenterZoom(
        widget.options.bounds!,
        widget.options.boundsOptions,
      );

      _mapState = _mapState.copyWith(zoom: target.zoom, center: target.center);
      _hasFitInitialBounds = true;
    }
  }

  void _updateAndEmitSizeIfConstraintsChanged(BoxConstraints constraints) {
    if (_mapState.nonrotatedSize.x != constraints.maxWidth ||
        _mapState.nonrotatedSize.y != constraints.maxHeight) {
      final oldMapState = _mapState;
      _mapState = _mapState.withNonotatedSize(
        CustomPoint<double>(constraints.maxWidth, constraints.maxHeight),
      );

      if (_mapState.nonrotatedSize != invalidSize) {
        _emitMapEvent(
          MapEventNonRotatedSizeChange(
            source: MapEventSource.nonRotatedSizeChange,
            oldMapState: oldMapState,
            mapState: _mapState,
          ),
        );
      }
    }
  }

  // During flutter startup the native platform resolution is not immediately
  // available which can cause constraints to be zero before they are updated
  // in a subsequent build to the actual constraints. This check allows us to
  // differentiate zero constraints caused by missing platform resolution vs
  // zero constraints which were actually provided by the parent widget.
  bool _parentConstraintsAreSet(
          BuildContext context, BoxConstraints constraints) =>
      constraints.maxWidth != 0 || MediaQuery.sizeOf(context) != Size.zero;

  void _emitMapEvent(MapEvent event) {
    if (event.source == MapEventSource.mapController && event is MapEventMove) {
      _flutterMapGestureDetectorKey.currentState
          ?.handleAnimationInterruptions(event);
    }

    widget.options.onMapEvent?.call(event);

    mapController.mapEventSink.add(event);
  }

  bool rotate(
    double newRotation, {
    bool hasGesture = false,
    required MapEventSource source,
    String? id,
  }) {
    if (newRotation != _mapState.rotation) {
      final oldMapState = _mapState;
      //Apply state then emit events and callbacks
      setState(() {
        _mapState = _mapState.withRotation(newRotation);
      });

      _emitMapEvent(
        MapEventRotate(
          id: id,
          source: source,
          oldMapState: oldMapState,
          mapState: _mapState,
        ),
      );
      return true;
    }

    return false;
  }

  MoveAndRotateResult rotateAroundPoint(
    double degree, {
    CustomPoint<double>? point,
    Offset? offset,
    bool hasGesture = false,
    required MapEventSource source,
    String? id,
  }) {
    if (point != null && offset != null) {
      throw ArgumentError('Only one of `point` or `offset` may be non-null');
    }
    if (point == null && offset == null) {
      throw ArgumentError('One of `point` or `offset` must be non-null');
    }

    if (degree == _mapState.rotation) return MoveAndRotateResult(false, false);

    if (offset == Offset.zero) {
      return MoveAndRotateResult(
        true,
        rotate(
          degree,
          hasGesture: hasGesture,
          source: source,
          id: id,
        ),
      );
    }

    final rotationDiff = degree - _mapState.rotation;
    final rotationCenter = _mapState.project(_mapState.center) +
        (point != null
                ? (point - (_mapState.nonrotatedSize / 2.0))
                : CustomPoint(offset!.dx, offset.dy))
            .rotate(_mapState.rotationRad);

    return MoveAndRotateResult(
      move(
        _mapState.unproject(
          rotationCenter +
              (_mapState.project(_mapState.center) - rotationCenter)
                  .rotate(degToRadian(rotationDiff)),
        ),
        _mapState.zoom,
        hasGesture: hasGesture,
        source: source,
        id: id,
      ),
      rotate(
        _mapState.rotation + rotationDiff,
        hasGesture: hasGesture,
        source: source,
        id: id,
      ),
    );
  }

  MoveAndRotateResult moveAndRotate(
    LatLng newCenter,
    double newZoom,
    double newRotation, {
    Offset offset = Offset.zero,
    required MapEventSource source,
    String? id,
    bool hasGesture = false,
  }) =>
      MoveAndRotateResult(
        move(
          newCenter,
          newZoom,
          offset: offset,
          id: id,
          source: source,
          hasGesture: hasGesture,
        ),
        rotate(newRotation, id: id, source: source, hasGesture: hasGesture),
      );

  bool move(
    LatLng newCenter,
    double newZoom, {
    Offset offset = Offset.zero,
    bool hasGesture = false,
    required MapEventSource source,
    String? id,
  }) {
    newZoom = _mapState.fitZoomToBounds(newZoom);

    // Algorithm thanks to https://github.com/tlserver/flutter_map_location_marker
    if (offset != Offset.zero) {
      final newPoint = widget.options.crs.latLngToPoint(newCenter, newZoom);
      newCenter = widget.options.crs.pointToLatLng(
        _mapState.rotatePoint(
          newPoint,
          newPoint - CustomPoint(offset.dx, offset.dy),
        ),
        newZoom,
      );
    }

    if (_mapState.isOutOfBounds(newCenter)) {
      if (!widget.options.slideOnBoundaries) return false;
      newCenter = _mapState.containPoint(newCenter, _mapState.center);
    }

    if (widget.options.maxBounds != null) {
      final adjustedCenter = _mapState.adjustCenterIfOutsideMaxBounds(
        newCenter,
        newZoom,
        widget.options.maxBounds!,
      );

      if (adjustedCenter == null) return false;
      newCenter = adjustedCenter;
    }

    if (newCenter == _mapState.center && newZoom == _mapState.zoom) {
      return false;
    }

    final oldMapState = _mapState;
    setState(() {
      _mapState = _mapState.copyWith(zoom: newZoom, center: newCenter);
    });

    final movementEvent = MapEventWithMove.fromSource(
      oldMapState: oldMapState,
      mapState: _mapState,
      hasGesture: hasGesture,
      source: source,
      id: id,
    );
    if (movementEvent != null) _emitMapEvent(movementEvent);

    widget.options.onPositionChanged?.call(
      MapPosition(
        center: newCenter,
        bounds: _mapState.bounds,
        zoom: newZoom,
        hasGesture: hasGesture,
      ),
      hasGesture,
    );

    return true;
  }

  bool fitBounds(
    LatLngBounds bounds,
    FitBoundsOptions options, {
    Offset offset = Offset.zero,
  }) {
    final target = _mapState.getBoundsCenterZoom(bounds, options);
    return move(
      target.center,
      target.zoom,
      offset: offset,
      source: MapEventSource.fitBounds,
    );
  }

  LatLng pointToLatLng(CustomPoint localPoint) =>
      _mapState.pointToLatLng(localPoint);

  CenterZoom centerZoomFitBounds(
          LatLngBounds bounds, FitBoundsOptions options) =>
      _mapState.centerZoomFitBounds(bounds, options);

  CustomPoint<double> latLngToScreenPoint(LatLng latLng) =>
      _mapState.latLngToScreenPoint(latLng);

  CustomPoint<double> rotatePoint(
    CustomPoint mapCenter,
    CustomPoint point, {
    bool counterRotation = true,
  }) =>
      _mapState.rotatePoint(
        mapCenter.toDoublePoint(),
        point.toDoublePoint(),
        counterRotation: counterRotation,
      );
}
