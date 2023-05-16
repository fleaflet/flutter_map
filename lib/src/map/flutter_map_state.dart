import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/gestures/gestures.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:flutter_map/src/map/map_state_widget.dart';
import 'package:latlong2/latlong.dart';

class FlutterMapState extends MapGestureMixin
    with AutomaticKeepAliveClientMixin {
  static const invalidSize = CustomPoint<double>(-1, -1);

  final _positionedTapController = PositionedTapController();
  final GestureArenaTeam _team = GestureArenaTeam();

  final MapController _localController = MapControllerImpl();

  bool _hasFitInitialBounds = false;

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

    // Initialize all variables here, if they need to be updated after the map changes
    // like center, or bounds they also need to be updated in build.
    _rotation = options.rotation;
    _center = options.center;
    _zoom = options.zoom;
    _pixelBounds = getPixelBounds();
    _bounds = _calculateBounds();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      options.onMapReady?.call();
    });
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
          instance.team ??= _team;
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
        // Update on layout change.
        setSize(constraints.maxWidth, constraints.maxHeight);

        // If bounds were provided set the initial center/zoom to match those
        // bounds once the parent constraints are available.
        if (options.bounds != null &&
            !_hasFitInitialBounds &&
            _parentConstraintsAreSet(context, constraints)) {
          final target =
              getBoundsCenterZoom(options.bounds!, options.boundsOptions);
          _zoom = target.zoom;
          _center = target.center;
          _hasFitInitialBounds = true;
        }

        _pixelBounds = getPixelBounds();
        _bounds = _calculateBounds();
        _pixelOrigin = getNewPixelOrigin(_center);

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
              onSecondaryTap: handleSecondaryTap,
              onLongPress: handleLongPress,
              onDoubleTap: handleDoubleTap,
              child: RawGestureDetector(
                gestures: gestures,
                child: _buildMap(),
              ),
            ),
          ),
        );
      },
    );
  }

  // During flutter startup the native platform resolution is not immediately
  // available which can cause constraints to be zero before they are updated
  // in a subsequent build to the actual constraints. This check allows us to
  // differentiate zero constraints caused by missing platform resolution vs
  // zero constraints which were actually provided by the parent widget.
  bool _parentConstraintsAreSet(
          BuildContext context, BoxConstraints constraints) =>
      constraints.maxWidth != 0 || MediaQuery.sizeOf(context) != Size.zero;

  Widget _buildMap() {
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

  ///MAP STATE
  ///MAP STATE
  ///MAP STATE
  ///MAP STATE
  ///MAP STATE
  ///MAP STATE
  ///MAP STATE
  ///MAP STATE

  late double _zoom;
  late double _rotation;

  double get zoom => _zoom;

  double get rotation => _rotation;

  double get rotationRad => degToRadian(_rotation);

  late CustomPoint<int> _pixelOrigin;

  CustomPoint<int> get pixelOrigin => _pixelOrigin;

  late LatLng _center;

  LatLng get center => _center;

  late LatLngBounds _bounds;

  LatLngBounds get bounds => _bounds;

  late Bounds<double> _pixelBounds;

  Bounds<double> get pixelBounds => _pixelBounds;

  // Original size of the map where rotation isn't calculated
  CustomPoint<double> _nonrotatedSize = invalidSize;

  CustomPoint<double> get nonrotatedSize => _nonrotatedSize;

  void setSize(double width, double height) {
    if (_nonrotatedSize.x != width || _nonrotatedSize.y != height) {
      final previousNonRotatedSize = _nonrotatedSize;

      _nonrotatedSize = CustomPoint<double>(width, height);
      _updateSizeByOriginalSizeAndRotation();

      if (previousNonRotatedSize != invalidSize) {
        emitMapEvent(
          MapEventNonRotatedSizeChange(
            source: MapEventSource.nonRotatedSizeChange,
            previousNonRotatedSize: previousNonRotatedSize,
            nonRotatedSize: _nonrotatedSize,
            center: center,
            zoom: zoom,
          ),
        );
      }
    }
  }

  // Extended size of the map where rotation is calculated
  CustomPoint<double> _size = invalidSize;

  CustomPoint<double> get size => _size;

  void _updateSizeByOriginalSizeAndRotation() {
    final originalWidth = _nonrotatedSize.x;
    final originalHeight = _nonrotatedSize.y;

    if (_rotation != 0.0) {
      final cosAngle = math.cos(rotationRad).abs();
      final sinAngle = math.sin(rotationRad).abs();
      final width = (originalWidth * cosAngle) + (originalHeight * sinAngle);
      final height = (originalHeight * cosAngle) + (originalWidth * sinAngle);

      _size = CustomPoint<double>(width, height);
    } else {
      _size = CustomPoint<double>(originalWidth, originalHeight);
    }

    _pixelOrigin = getNewPixelOrigin(_center);
  }

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
    if (newRotation != _rotation) {
      final double oldRotation = _rotation;
      //Apply state then emit events and callbacks
      setState(() {
        _rotation = newRotation;
      });
      _updateSizeByOriginalSizeAndRotation();

      emitMapEvent(
        MapEventRotate(
          id: id,
          currentRotation: oldRotation,
          targetRotation: _rotation,
          center: _center,
          zoom: _zoom,
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

  bool move(
    LatLng newCenter,
    double newZoom, {
    bool hasGesture = false,
    required MapEventSource source,
    String? id,
  }) {
    newZoom = fitZoomToBounds(newZoom);

    if (newCenter == _center && newZoom == _zoom) return false;

    if (isOutOfBounds(newCenter)) {
      if (!options.slideOnBoundaries) {
        return false;
      }
      newCenter = containPoint(newCenter, _center);
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

    final LatLng oldCenter = _center;
    final double oldZoom = _zoom;

    //Apply state then emit events and callbacks
    setState(() {
      _zoom = newZoom;
      _center = newCenter;
    });

    _pixelBounds = getPixelBounds();
    _bounds = _calculateBounds();
    _pixelOrigin = getNewPixelOrigin(newCenter);

    final movementEvent = MapEventWithMove.fromSource(
      targetCenter: newCenter,
      targetZoom: newZoom,
      oldCenter: oldCenter,
      oldZoom: oldZoom,
      hasGesture: hasGesture,
      source: source,
    );
    if (movementEvent != null) emitMapEvent(movementEvent);

    options.onPositionChanged?.call(
      MapPosition(
        center: newCenter,
        bounds: _bounds,
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

  void fitBounds(LatLngBounds bounds, FitBoundsOptions options) {
    final target = getBoundsCenterZoom(bounds, options);
    move(target.center, target.zoom, source: MapEventSource.fitBounds);
  }

  CenterZoom centerZoomFitBounds(
      LatLngBounds bounds, FitBoundsOptions options) {
    return getBoundsCenterZoom(bounds, options);
  }

  LatLngBounds _calculateBounds() {
    return LatLngBounds(
      unproject(_pixelBounds.bottomLeft),
      unproject(_pixelBounds.topRight),
    );
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
    size = CustomPoint(math.max(0, size.x), math.max(0, size.y));
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

  CustomPoint<double> project(LatLng latlng, [double? zoom]) {
    zoom ??= _zoom;
    return options.crs.latLngToPoint(latlng, zoom);
  }

  LatLng unproject(CustomPoint point, [double? zoom]) {
    zoom ??= _zoom;
    return options.crs.pointToLatLng(point, zoom)!;
  }

  LatLng layerPointToLatLng(CustomPoint point) {
    return unproject(point);
  }

  double getZoomScale(double toZoom, double fromZoom) {
    final crs = options.crs;
    return crs.scale(toZoom) / crs.scale(fromZoom);
  }

  double getScaleZoom(double scale, double? fromZoom) {
    final crs = options.crs;
    fromZoom = fromZoom ?? _zoom;
    return crs.zoom(scale * crs.scale(fromZoom));
  }

  Bounds? getPixelWorldBounds(double? zoom) {
    return options.crs.getProjectedBounds(zoom ?? _zoom);
  }

  Offset getOffsetFromOrigin(LatLng pos) {
    final delta = project(pos) - _pixelOrigin;
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

  // This will convert a latLng to a position that we could use with a widget
  // outside of FlutterMap layer space. Eg using a Positioned Widget.
  CustomPoint<double> latLngToScreenPoint(LatLng latLng) {
    final nonRotatedPixelOrigin =
        (project(_center, zoom) - _nonrotatedSize / 2.0).round();

    var point = options.crs.latLngToPoint(latLng, zoom);

    final mapCenter = options.crs.latLngToPoint(center, zoom);

    if (rotation != 0.0) {
      point = rotatePoint(mapCenter, point, counterRotation: false);
    }

    return point - nonRotatedPixelOrigin;
  }

  LatLng? pointToLatLng(CustomPoint localPoint) {
    final localPointCenterDistance = CustomPoint(
      (_nonrotatedSize.x / 2) - localPoint.x,
      (_nonrotatedSize.y / 2) - localPoint.y,
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

  _SafeArea? _safeAreaCache;
  double? _safeAreaZoom;

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
    final controllerZoom = _zoom;
    if (controllerZoom != _safeAreaZoom || _safeAreaCache == null) {
      _safeAreaZoom = controllerZoom;
      final halfScreenHeight = _calculateScreenHeightInDegrees() / 2;
      final halfScreenWidth = _calculateScreenWidthInDegrees() / 2;
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

  double _calculateScreenWidthInDegrees() {
    final degreesPerPixel = 360 / math.pow(2, zoom + 8);
    return options.screenSize!.width * degreesPerPixel;
  }

  double _calculateScreenHeightInDegrees() =>
      options.screenSize!.height * 170.102258 / math.pow(2, zoom + 8);

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
