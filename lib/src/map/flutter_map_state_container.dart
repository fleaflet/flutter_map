import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/gestures.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:flutter_map/src/map/flutter_map_state_inherited_widget.dart';
import 'package:flutter_map/src/misc/private/bounds.dart';
import 'package:latlong2/latlong.dart';

class FlutterMapStateContainer extends MapGestureMixin {
  static const invalidSize = CustomPoint<double>(-1, -1);

  final _positionedTapController = PositionedTapController();
  final _gestureArenaTeam = GestureArenaTeam();

  bool _hasFitInitialBounds = false;

  @override
  FlutterMapState get mapState => _mapState;

// TODO Should override methods like move() instead.
  @override
  FlutterMapStateContainer get mapStateContainer => this;

  final _localController = MapController();
  @override
  MapController get mapController => widget.mapController ?? _localController;

  @override
  MapOptions get options => widget.options;

  late FlutterMapState _mapState;

  LatLng get center => _mapState.center;

  LatLngBounds get bounds => _mapState.bounds;

  double get zoom => _mapState.zoom;

  double get rotation => _mapState.rotation;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => options.onMapReady?.call());

    _mapState = FlutterMapState(
      options: options,
      center: options.center,
      zoom: options.zoom,
      rotation: options.rotation,
      nonrotatedSize: invalidSize,
      size: invalidSize,
      hasFitInitialBounds: _hasFitInitialBounds,
    );
  }

  @override
  void didUpdateWidget(FlutterMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // TODO update the map state appropriately.
  }

  @override
  Widget build(BuildContext context) {
    final DeviceGestureSettings gestureSettings =
        MediaQuery.gestureSettingsOf(context);
    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};

    gestures[TapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
      () => TapGestureRecognizer(debugOwner: this),
      (TapGestureRecognizer instance) {
        instance
          ..onTapDown = _positionedTapController.onTapDown
          ..onTapUp = handleOnTapUp
          ..onTap = _positionedTapController.onTap
          ..onSecondaryTap = _positionedTapController.onSecondaryTap
          ..onSecondaryTapDown = _positionedTapController.onTapDown;
      },
    );

    gestures[LongPressGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
      () => LongPressGestureRecognizer(debugOwner: this),
      (LongPressGestureRecognizer instance) {
        instance.onLongPress = _positionedTapController.onLongPress;
      },
    );

    if (InteractiveFlag.hasFlag(
        options.interactiveFlags, InteractiveFlag.drag)) {
      gestures[VerticalDragGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
        () => VerticalDragGestureRecognizer(debugOwner: this),
        (VerticalDragGestureRecognizer instance) {
          instance.onUpdate = (details) {
            // Absorbing vertical drags
          };
          instance.gestureSettings = gestureSettings;
          instance.team ??= _gestureArenaTeam;
        },
      );
      gestures[HorizontalDragGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
        () => HorizontalDragGestureRecognizer(debugOwner: this),
        (HorizontalDragGestureRecognizer instance) {
          instance.onUpdate = (details) {
            // Absorbing horizontal drags
          };
          instance.gestureSettings = gestureSettings;
          instance.team ??= _gestureArenaTeam;
        },
      );
    }

    gestures[ScaleGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
      () => ScaleGestureRecognizer(debugOwner: this),
      (ScaleGestureRecognizer instance) {
        instance
          ..onStart = handleScaleStart
          ..onUpdate = handleScaleUpdate
          ..onEnd = handleScaleEnd;
        instance.team ??= _gestureArenaTeam;
        _gestureArenaTeam.captain = instance;
      },
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _onConstraintsChange(constraints);

        return MapStateInheritedWidget(
          mapController: mapController,
          mapState: _mapState,
          child: Listener(
            onPointerDown: onPointerDown,
            onPointerUp: onPointerUp,
            onPointerCancel: onPointerCancel,
            onPointerHover: onPointerHover,
            onPointerSignal: onPointerSignal,
            child: PositionedTapDetector2(
              controller: _positionedTapController,
              onTap: handleTap,
              onSecondaryTap: handleSecondaryTap,
              onLongPress: handleLongPress,
              onDoubleTap: handleDoubleTap,
              doubleTapDelay: InteractiveFlag.hasFlag(
                options.interactiveFlags,
                InteractiveFlag.doubleTapZoom,
              )
                  ? null
                  : Duration.zero,
              child: RawGestureDetector(
                gestures: gestures,
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
            ),
          ),
        );
      },
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
    if (options.bounds != null &&
        !_hasFitInitialBounds &&
        _parentConstraintsAreSet(context, constraints)) {
      final target = _mapState.getBoundsCenterZoom(
        options.bounds!,
        options.boundsOptions,
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
        emitMapEvent(
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

  void emitMapEvent(MapEvent event) {
    if (event.source == MapEventSource.mapController && event is MapEventMove) {
      handleAnimationInterruptions(event);
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

      emitMapEvent(
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
  }) =>
      MoveAndRotateResult(
        move(newCenter, newZoom, offset: offset, id: id, source: source),
        rotate(newRotation, id: id, source: source),
      );

  bool move(
    LatLng newCenter,
    double newZoom, {
    Offset offset = Offset.zero,
    bool hasGesture = false,
    required MapEventSource source,
    String? id,
  }) {
    newZoom = fitZoomToBounds(newZoom);

    // Algorithm thanks to https://github.com/tlserver/flutter_map_location_marker
    if (offset != Offset.zero) {
      final newPoint = options.crs.latLngToPoint(newCenter, newZoom);
      newCenter = options.crs.pointToLatLng(
        rotatePoint(
          newPoint,
          newPoint - CustomPoint(offset.dx, offset.dy),
        ),
        newZoom,
      );
    }

    if (isOutOfBounds(newCenter)) {
      if (!options.slideOnBoundaries) return false;
      newCenter = containPoint(newCenter, _mapState.center);
    }

    if (options.maxBounds != null) {
      final adjustedCenter = adjustCenterIfOutsideMaxBounds(
        newCenter,
        newZoom,
        options.maxBounds!,
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
    if (movementEvent != null) emitMapEvent(movementEvent);

    options.onPositionChanged?.call(
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

  CenterZoom centerZoomFitBounds(
    LatLngBounds bounds,
    FitBoundsOptions options,
  ) =>
      _mapState.getBoundsCenterZoom(bounds, options);

  double getBoundsZoom(
    LatLngBounds bounds,
    CustomPoint<double> padding, {
    bool inside = false,
    bool forceIntegerZoomLevel = false,
  }) =>
      _mapState.getBoundsZoom(
        bounds,
        padding,
        inside: inside,
        forceIntegerZoomLevel: forceIntegerZoomLevel,
      );

  double getZoomScale(double toZoom, double fromZoom) =>
      _mapState.getZoomScale(toZoom, fromZoom);

  double getScaleZoom(double scale, double? fromZoom) =>
      _mapState.getScaleZoom(scale, fromZoom);

  Bounds? getPixelWorldBounds(double? zoom) =>
      _mapState.getPixelWorldBounds(zoom);

  Offset getOffsetFromOrigin(LatLng pos) => _mapState.getOffsetFromOrigin(pos);

  CustomPoint<int> getNewPixelOrigin(LatLng center, [double? zoom]) =>
      _mapState.getNewPixelOrigin(center, zoom);

  Bounds<double> getPixelBounds([double? zoom]) =>
      _mapState.getPixelBounds(zoom);

  LatLng? adjustCenterIfOutsideMaxBounds(
      LatLng testCenter, double testZoom, LatLngBounds maxBounds) {
    LatLng? newCenter;

    final swPixel = _mapState.project(maxBounds.southWest, testZoom);
    final nePixel = _mapState.project(maxBounds.northEast, testZoom);

    final centerPix = _mapState.project(testCenter, testZoom);

    final halfSizeX = _mapState.size.x / 2;
    final halfSizeY = _mapState.size.y / 2;

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
      newCenter = _mapState.unproject(CustomPoint(newCx, newCy), testZoom);
    }

    return newCenter;
  }

  // This will convert a latLng to a position that we could use with a widget
  // outside of FlutterMap layer space. Eg using a Positioned Widget.
  CustomPoint<double> latLngToScreenPoint(LatLng latLng) =>
      _mapState.latLngToScreenPoint(latLng);

  LatLng pointToLatLng(CustomPoint localPoint) =>
      _mapState.pointToLatLng(localPoint);

  // Sometimes we need to make allowances that a rotation already exists, so
  // it needs to be reversed (pointToLatLng), and sometimes we want to use
  // the same rotation to create a new position (latLngToScreenpoint).
  // counterRotation just makes allowances this for this.
  CustomPoint<double> rotatePoint(
    CustomPoint<double> mapCenter,
    CustomPoint<double> point, {
    bool counterRotation = true,
  }) =>
      _mapState.rotatePoint(mapCenter, point, counterRotation: counterRotation);

  //if there is a pan boundary, do not cross
  bool isOutOfBounds(LatLng center) => _mapState.isOutOfBounds(center);

  LatLng containPoint(LatLng point, LatLng fallback) =>
      _mapState.containPoint(point, fallback);
}
