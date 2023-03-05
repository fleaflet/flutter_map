import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/gestures.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:flutter_map/src/map/map_state_widget.dart';
import 'package:latlong2/latlong.dart';
import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart';
import 'dart:math' as math;
import 'package:flutter_map/src/core/bounds.dart';

class FlutterMapState extends MapGestureMixin
    with AutomaticKeepAliveClientMixin {
  final _positionedTapController = PositionedTapController();
  final GestureArenaTeam _team = GestureArenaTeam();

  final MapController _localController = MapControllerImpl();

  @override
  MapOptions get options => widget.options;

  @override
  FlutterMapState get mapState => this;

  @override
  MapController get mapController => widget.mapController ?? _localController;

  @override
  void initState() {
    super.initState();

    mapController.state = this;

    LatLng center = options.center;
    double zoom = options.zoom;
    if (options.bounds != null) {
      final target =
          getBoundsCenterZoom(options.bounds!, options.boundsOptions);
      center = target.center;
      zoom = target.zoom;
    }

    // Initialize core state here. State that needs to be updated after a map
    // changes like: move center, or zoom in/out.
    _state = ValueNotifier(_State(options.crs, center, zoom, options.rotation));

    final onMapReady = options.onMapReady;
    if (onMapReady != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onMapReady());
    }
  }

  //This may not be required.
  @override
  void didUpdateWidget(FlutterMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    mapController.state = this;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final DeviceGestureSettings? gestureSettings =
        MediaQuery.maybeOf(context)?.gestureSettings;
    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};

    gestures[TapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
      () => TapGestureRecognizer(debugOwner: this),
      (TapGestureRecognizer instance) {
        instance
          ..onTapDown = _positionedTapController.onTapDown
          ..onTapUp = handleOnTapUp
          ..onTap = _positionedTapController.onTap;
        // ..onTapCancel = onTapCancel
        // ..onSecondaryTap = onSecondaryTap
        // ..onSecondaryTapDown = onSecondaryTapDown
        // ..onSecondaryTapUp = onSecondaryTapUp
        // ..onSecondaryTapCancel = onSecondaryTapCancel
        // ..onTertiaryTapDown = onTertiaryTapDown
        // ..onTertiaryTapUp = onTertiaryTapUp
        // ..onTertiaryTapCancel = onTertiaryTapCancel
        // ..gestureSettings = gestureSettings;
        // instance.team = _team;
      },
    );

    gestures[LongPressGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
      () => LongPressGestureRecognizer(debugOwner: this),
      (LongPressGestureRecognizer instance) {
        instance.onLongPress = _positionedTapController.onLongPress;
        // ..onLongPressDown = onLongPressDown
        // ..onLongPressCancel = onLongPressCancel
        // ..onLongPressStart = onLongPressStart
        // ..onLongPressMoveUpdate = onLongPressMoveUpdate
        // ..onLongPressUp = onLongPressUp
        // ..onLongPressEnd = onLongPressEnd
        // ..onSecondaryLongPressDown = onSecondaryLongPressDown
        // ..onSecondaryLongPressCancel = onSecondaryLongPressCancel
        // ..onSecondaryLongPress = onSecondaryLongPress
        // ..onSecondaryLongPressStart = onSecondaryLongPressStart
        // ..onSecondaryLongPressMoveUpdate = onSecondaryLongPressMoveUpdate
        // ..onSecondaryLongPressUp = onSecondaryLongPressUp
        // ..onSecondaryLongPressEnd = onSecondaryLongPressEnd
        // ..onTertiaryLongPressDown = onTertiaryLongPressDown
        // ..onTertiaryLongPressCancel = onTertiaryLongPressCancel
        // ..onTertiaryLongPress = onTertiaryLongPress
        // ..onTertiaryLongPressStart = onTertiaryLongPressStart
        // ..onTertiaryLongPressMoveUpdate = onTertiaryLongPressMoveUpdate
        // ..onTertiaryLongPressUp = onTertiaryLongPressUp
        // ..onTertiaryLongPressEnd = onTertiaryLongPressEnd
        // ..gestureSettings = gestureSettings;
        // instance.team = _team;
      },
    );

    if (options.absorbPanEventsOnScrollables &&
        InteractiveFlag.hasFlag(
            options.interactiveFlags, InteractiveFlag.drag)) {
      gestures[VerticalDragGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
        () => VerticalDragGestureRecognizer(debugOwner: this),
        (VerticalDragGestureRecognizer instance) {
          instance.onUpdate = (details) {
            //Absorbing vertical drags
          };
          // ..dragStartBehavior = dragStartBehavior
          instance.gestureSettings = gestureSettings;
          instance.team ??= _team;
        },
      );
      gestures[HorizontalDragGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
        () => HorizontalDragGestureRecognizer(debugOwner: this),
        (HorizontalDragGestureRecognizer instance) {
          instance.onUpdate = (details) {
            //Absorbing horizontal drags
          };
          // ..dragStartBehavior = dragStartBehavior
          instance.gestureSettings = gestureSettings;
          instance.team ??= _team;
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
        instance.team ??= _team;
        _team.captain = instance;
      },
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        //Update on layout change
        _nonrotatedSize =
            CustomPoint<double>(constraints.maxWidth, constraints.maxHeight);
        _state.value = _State(options.crs, center, zoom, rotation);

        return ValueListenableBuilder<_State>(
            valueListenable: _state,
            builder: (BuildContext ctx, _State settings, Widget? __) {
              return MapStateInheritedWidget(
                mapState: this,
                child: Listener(
                  onPointerDown: onPointerDown,
                  onPointerUp: onPointerUp,
                  onPointerCancel: onPointerCancel,
                  onPointerHover: onPointerHover,
                  onPointerSignal: onPointerSignal,
                  child: PositionedTapDetector2(
                    controller: _positionedTapController,
                    onTap: handleTap,
                    onLongPress: handleLongPress,
                    onDoubleTap: handleDoubleTap,
                    child: RawGestureDetector(
                        gestures: gestures, child: _buildMap(size)),
                  ),
                ),
              );
            });
      },
    );
  }

  Widget _buildMap(CustomPoint<double> size) {
    return ClipRect(
      child: Stack(
        children: [
          OverflowBox(
            minWidth: size.x,
            maxWidth: size.x,
            minHeight: size.y,
            maxHeight: size.y,
            child: Transform.rotate(
              angle: rotationRad,
              child: Stack(
                children: widget.children,
              ),
            ),
          ),
          Stack(
            children: widget.nonRotatedChildren,
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => options.keepAlive;

  // Map state: center, zoom, rotation, and nonrotated layout size. All other
  // quantities are derived.
  late final ValueNotifier<_State> _state;

  // Original size of the map w/o rotation applied yet. Initially set to zero
  // to update it on first build, since we need the `LayoutBuilder` to tell us
  // the layout constraints.
  late CustomPoint<double> _nonrotatedSize;

  // End map state

  LatLng get center => _state.value.center;
  double get zoom => _state.value.zoom;
  double get rotation => _state.value.rotation;
  double get rotationRad => degToRadian(rotation);
  CustomPoint<double> get nonrotatedSize => _nonrotatedSize;

  // Cache derived quantities like size and _safeArea. Rebuild the cache
  // whenever the state changes.
  _Cache? _cache;
  _Cache get _cached {
    if (_cache?._state != _state.value) {
      _cache = _Cache(_state.value);
    }
    return _cache!;
  }

  CustomPoint get pixelOrigin {
    _cached.pixelOrigin ??= _state.value.getPixelOrigin(size);
    return _cached.pixelOrigin!;
  }

  Bounds get pixelBounds {
    _cached.pixelBounds ??= _state.value.getPixelBounds(size);
    return _cached.pixelBounds!;
  }

  LatLngBounds get bounds {
    _cached.bounds ??= _state.value.getBounds(size);
    return _cached.bounds!;
  }

  // Extended size of the map where rotation is calculated
  CustomPoint<double> get size {
    _cached.size ??=
        _getSizeByOriginalSizeAndRotation(nonrotatedSize, rotationRad);
    return _cached.size!;
  }

  _SafeArea get _safeArea {
    _cached.safeArea ??= _getSafeArea(zoom);
    return _cached.safeArea!;
  }

  static CustomPoint<double> _getSizeByOriginalSizeAndRotation(
      CustomPoint<double> nonrotatedSize, double rotationRad) {
    final originalWidth = nonrotatedSize.x;
    final originalHeight = nonrotatedSize.y;

    if (rotationRad != 0.0) {
      final cosAngle = math.cos(rotationRad).abs();
      final sinAngle = math.sin(rotationRad).abs();
      final double width =
          (originalWidth * cosAngle) + (originalHeight * sinAngle);
      final double height =
          (originalHeight * cosAngle) + (originalWidth * sinAngle);

      return CustomPoint<double>(width, height);
    }
    return CustomPoint<double>(originalWidth, originalHeight);
  }

  void _handleMoveEmit(LatLng targetCenter, double targetZoom, LatLng oldCenter,
      double oldZoom, MapEventSource source, String? id) {
    if (source == MapEventSource.flingAnimationController) {
      emitMapEvent(
        MapEventFlingAnimation(
          center: oldCenter,
          zoom: oldZoom,
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
        ),
      );
    } else if (source == MapEventSource.doubleTapZoomAnimationController) {
      emitMapEvent(
        MapEventDoubleTapZoom(
          center: oldCenter,
          zoom: oldZoom,
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
        ),
      );
    } else if (source == MapEventSource.scrollWheel) {
      emitMapEvent(
        MapEventScrollWheelZoom(
          center: oldCenter,
          zoom: oldZoom,
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
        ),
      );
    } else if (source == MapEventSource.onDrag ||
        source == MapEventSource.onMultiFinger) {
      emitMapEvent(
        MapEventMove(
          center: oldCenter,
          zoom: oldZoom,
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
        ),
      );
    } else if (source == MapEventSource.mapController) {
      emitMapEvent(
        MapEventMove(
          id: id,
          center: oldCenter,
          zoom: oldZoom,
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
        ),
      );
    } else if (source == MapEventSource.custom) {
      // for custom source, emit move event if zoom or center has changed
      if (targetZoom != oldZoom ||
          targetCenter.latitude != oldCenter.latitude ||
          targetCenter.longitude != oldCenter.longitude) {
        emitMapEvent(
          MapEventMove(
            id: id,
            center: oldCenter,
            zoom: oldZoom,
            targetCenter: targetCenter,
            targetZoom: targetZoom,
            source: source,
          ),
        );
      }
    }
  }

  void emitMapEvent(MapEvent event) {
    if (event.source == MapEventSource.mapController && event is MapEventMove) {
      handleAnimationInterruptions(event);
    }

    final onMapEvent = widget.options.onMapEvent;
    if (onMapEvent != null) {
      // NOTE: The onMapEvent handler is called in a `setState` in case the
      // handler itself changes the map's state. This is quite a bit of
      // overhead for handlers w/o side-effects. In that case it would be
      // cheaper to use the listener API instead.
      setState(() => onMapEvent(event));
    }
    mapController.mapEventSink.add(event);
  }

  bool rotate(
    double newRotation, {
    bool hasGesture = false,
    required MapEventSource source,
    String? id,
  }) {
    if (newRotation != rotation) {
      final double oldRotation = rotation;
      //Apply state then emit events and callbacks
      _state.value = _state.value.fromRotation(newRotation);

      emitMapEvent(
        MapEventRotate(
          id: id,
          currentRotation: oldRotation,
          targetRotation: rotation,
          center: center,
          zoom: zoom,
          source: source,
        ),
      );
      return true;
    }

    return false;
  }

  MoveAndRotateResult moveAndRotate(
      LatLng newCenter, double newZoom, double newRotation,
      {required MapEventSource source, String? id}) {
    final moveSucc = move(newCenter, newZoom, id: id, source: source);
    final rotateSucc = rotate(newRotation, id: id, source: source);

    return MoveAndRotateResult(moveSucc, rotateSucc);
  }

  bool move(LatLng newCenter, double newZoom,
      {bool hasGesture = false, required MapEventSource source, String? id}) {
    newZoom = fitZoomToBounds(newZoom);
    final mapMoved = newCenter != center || newZoom != zoom;
    if (!mapMoved) {
      return false;
    }

    if (isOutOfBounds(newCenter)) {
      if (!options.slideOnBoundaries) {
        return false;
      }
      newCenter = containPoint(newCenter, center);
    }

    // Try and fit the corners of the map inside the visible area.
    // If it's still outside (so response is null), don't perform a move.
    if (options.maxBounds != null) {
      final adjustedCenter = adjustCenterIfOutsideMaxBounds(
          newCenter, newZoom, options.maxBounds!);
      if (adjustedCenter == null) {
        return false;
      } else {
        newCenter = adjustedCenter;
      }
    }

    final LatLng oldCenter = center;
    final double oldZoom = zoom;

    // Apply state then emit events and callbacks
    _state.value = _state.value.fromLocation(newCenter, newZoom);

    _handleMoveEmit(newCenter, newZoom, oldCenter, oldZoom, source, id);

    options.onPositionChanged?.call(
        MapPosition(
            center: newCenter,
            bounds: bounds,
            zoom: newZoom,
            hasGesture: hasGesture),
        hasGesture);

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

  void fitBounds(LatLngBounds bounds, FitBoundsOptions options) {
    if (!bounds.isValid) {
      throw Exception('Bounds are not valid.');
    }
    final target = getBoundsCenterZoom(bounds, options);
    move(target.center, target.zoom, source: MapEventSource.fitBounds);
  }

  CenterZoom centerZoomFitBounds(
      LatLngBounds bounds, FitBoundsOptions options) {
    if (!bounds.isValid) {
      throw Exception('Bounds are not valid.');
    }
    return getBoundsCenterZoom(bounds, options);
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
    final center = unproject((swPoint + nePoint) / 2 + paddingOffset, zoom);
    return CenterZoom(
      center: center,
      zoom: zoom,
    );
  }

  double getBoundsZoom(LatLngBounds bounds, CustomPoint<double> padding,
      {bool inside = false, bool forceIntegerZoomLevel = false}) {
    var zoom = this.zoom;
    final min = options.minZoom ?? 0.0;
    final max = options.maxZoom ?? double.infinity;
    final nw = bounds.northWest;
    final se = bounds.southEast;
    var size = this.size - padding;
    // Prevent negative size which results in NaN zoom value later on in the calculation
    size = CustomPoint(math.max(0.0, size.x), math.max(0.0, size.y));
    final boundsSize = Bounds(project(se, zoom), project(nw, zoom)).size;
    final scaleX = size.x / boundsSize.x;
    final scaleY = size.y / boundsSize.y;
    final scale = inside ? math.max(scaleX, scaleY) : math.min(scaleX, scaleY);

    zoom = getScaleZoom(scale, zoom);

    if (forceIntegerZoomLevel) {
      zoom = inside ? zoom.ceilToDouble() : zoom.floorToDouble();
    }

    return math.max(min, math.min(max, zoom));
  }

  CustomPoint project(LatLng latlng, [double? targetZoom]) =>
      options.crs.latLngToPoint(latlng, targetZoom ?? zoom);

  LatLng unproject(CustomPoint point, [double? targetZoom]) =>
      options.crs.pointToLatLng(point, targetZoom ?? zoom)!;

  LatLng layerPointToLatLng(CustomPoint point) {
    return unproject(point);
  }

  double getZoomScale(double toZoom, double? fromZoom) {
    final crs = options.crs;
    return crs.scale(toZoom) / crs.scale(fromZoom ?? _state.value.zoom);
  }

  double getScaleZoom(double scale, double? fromZoom) {
    final crs = options.crs;
    fromZoom = fromZoom ?? _state.value.zoom;
    return crs.zoom(scale * crs.scale(fromZoom));
  }

  Bounds? getPixelWorldBounds(double? zoom) {
    return options.crs.getProjectedBounds(zoom ?? _state.value.zoom);
  }

  Offset getOffsetFromOrigin(LatLng pos) {
    final delta = project(pos) - pixelOrigin;
    return Offset(delta.x.toDouble(), delta.y.toDouble());
  }

  CustomPoint getNewPixelOrigin(LatLng center, [double? zoom]) {
    final viewHalf = size / 2.0;
    return (project(center, zoom) - viewHalf).round();
  }

  Bounds getPixelBounds(double zoom) =>
      _getPixelBounds(options.crs, center, zoom, size);

  LatLng? adjustCenterIfOutsideMaxBounds(
      LatLng testCenter, double testZoom, LatLngBounds maxBounds) {
    LatLng? newCenter;

    final swPixel = project(maxBounds.southWest!, testZoom);
    final nePixel = project(maxBounds.northEast!, testZoom);

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

  // This will convert a LatLng to a position that we could use with a widget
  // outside of FlutterMap layer space. Eg using a Positioned Widget.
  CustomPoint latLngToScreenPoint(LatLng latLng) {
    final nonRotatedPixelOrigin =
        (project(_state.value.center, zoom) - nonrotatedSize / 2.0).round();

    var point = options.crs.latLngToPoint(latLng, zoom);

    final mapCenter = options.crs.latLngToPoint(center, zoom);

    if (rotation != 0.0) {
      point = rotatePoint(mapCenter, point, counterRotation: false);
    }

    return point - nonRotatedPixelOrigin;
  }

  LatLng? pointToLatLng(CustomPoint localPoint) {
    final width = nonrotatedSize.x;
    final height = nonrotatedSize.y;

    final localPointCenterDistance =
        CustomPoint((width / 2) - localPoint.x, (height / 2) - localPoint.y);
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
  CustomPoint<num> rotatePoint(
      CustomPoint<num> mapCenter, CustomPoint<num> point,
      {bool counterRotation = true}) {
    final counterRotationFactor = counterRotation ? -1 : 1;

    final m = Matrix4.identity()
      ..translate(mapCenter.x.toDouble(), mapCenter.y.toDouble())
      ..rotateZ(rotationRad * counterRotationFactor)
      ..translate(-mapCenter.x.toDouble(), -mapCenter.y.toDouble());

    final tp = MatrixUtils.transformPoint(
        m, Offset(point.x.toDouble(), point.y.toDouble()));

    return CustomPoint(tp.dx, tp.dy);
  }

  //if there is a pan boundary, do not cross
  bool isOutOfBounds(LatLng center) {
    if (options.adaptiveBoundaries) {
      return !_safeArea.contains(center);
    }
    if (options.swPanBoundary != null && options.nePanBoundary != null) {
      if (center == null) {
        return true;
      } else if (center.latitude < options.swPanBoundary!.latitude ||
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
      return _safeArea.containPoint(point, fallback);
    } else {
      return LatLng(
        point.latitude.clamp(
            options.swPanBoundary!.latitude, options.nePanBoundary!.latitude),
        point.longitude.clamp(
            options.swPanBoundary!.longitude, options.nePanBoundary!.longitude),
      );
    }
  }

  _SafeArea _getSafeArea(double zoom) {
    final halfScreenHeight = _calculateScreenHeightInDegrees(zoom) / 2;
    final halfScreenWidth = _calculateScreenWidthInDegrees(zoom) / 2;
    final southWestLatitude =
        options.swPanBoundary!.latitude + halfScreenHeight;
    final southWestLongitude =
        options.swPanBoundary!.longitude + halfScreenWidth;
    final northEastLatitude =
        options.nePanBoundary!.latitude - halfScreenHeight;
    final northEastLongitude =
        options.nePanBoundary!.longitude - halfScreenWidth;
    return _SafeArea(
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

  double _calculateScreenWidthInDegrees(double zoom) {
    final degreesPerPixel = 360 / math.pow(2, zoom + 8);
    return options.screenSize!.width * degreesPerPixel;
  }

  double _calculateScreenHeightInDegrees(double zoom) =>
      options.screenSize!.height * 170.102258 / math.pow(2, zoom + 8);

  static FlutterMapState? maybeOf(BuildContext context, {bool nullOk = false}) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<MapStateInheritedWidget>();
    if (nullOk || widget != null) {
      return widget?.mapState;
    }
    throw FlutterError(
        'MapState.of() called with a context that does not contain a FlutterMap.');
  }
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

// Immutable representation of the Map's state (minus layout bounds). Other
// quantities are derived quantities.
class _State {
  final Crs _crs;
  final LatLng center;
  final double zoom;
  final double rotation;

  const _State(this._crs, this.center, this.zoom, this.rotation);

  _State fromRotation(double rotation) => _State(_crs, center, zoom, rotation);
  _State fromLocation(LatLng center, double zoom) =>
      _State(_crs, center, zoom, rotation);

  Bounds getPixelBounds(CustomPoint<double> size) =>
      _getPixelBounds(_crs, center, zoom, size);

  LatLngBounds getBounds(CustomPoint<double> size) {
    final pixelBounds = getPixelBounds(size);
    return LatLngBounds(
      _crs.pointToLatLng(pixelBounds.bottomLeft, zoom)!,
      _crs.pointToLatLng(pixelBounds.topRight, zoom)!,
    );
  }

  CustomPoint getPixelOrigin(CustomPoint<double> size) {
    final viewHalf = size / 2.0;
    return (_crs.latLngToPoint(center, zoom) - viewHalf).round();
  }
}

// Cache abstraction for derived quantities. Need to be recomputed whenever
// `_State` changes.
class _Cache {
  final _State _state;

  _Cache(this._state);

  Bounds? pixelBounds;
  LatLngBounds? bounds;
  CustomPoint? pixelOrigin;
  CustomPoint<double>? size;
  _SafeArea? safeArea;
}

Bounds _getPixelBounds(
    Crs crs, LatLng center, double zoom, CustomPoint<double> size) {
  final pixelCenter = crs.latLngToPoint(center, zoom).floor();
  final halfSize = size / 2;
  return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
}
