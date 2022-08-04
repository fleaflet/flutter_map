import 'dart:async';

import 'package:flutter/gestures.dart';
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

    //TODO there has to be a better way to pass state to my controller
    mapController.state = this;

    // Initialize all variables here, if they need to be updated after the map changes
    // like center, or bounds they also need to be updated in build.
    _rotation = options.rotation;
    _zoom = options.zoom;
    _rotationRad = degToRadian(options.rotation);
    _pixelBounds = getPixelBounds(zoom);
    _bounds = _calculateBounds();

    move(options.center, zoom, source: MapEventSource.initialization);

    // Funally, fit the map to restrictions
    if (options.bounds != null) {
      fitBounds(options.bounds!, options.boundsOptions);
    }
  }

  @override
  void dispose() {
    _localController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      setOriginalSize(constraints.maxWidth, constraints.maxHeight);

      _rotationRad = degToRadian(rotation);
      _pixelBounds = getPixelBounds(zoom);
      _bounds = _calculateBounds();

      if (options.bounds != null) {
        fitBounds(options.bounds!, options.boundsOptions);
      }


      final scaleGestureTeam = GestureArenaTeam();

      RawGestureDetector scaleGestureDetector({required Widget child}) =>
          RawGestureDetector(
            gestures: <Type, GestureRecognizerFactory>{
              ScaleGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
                      () => ScaleGestureRecognizer(),
                      (ScaleGestureRecognizer instance) {
                scaleGestureTeam.captain = instance;
                instance.team ??= scaleGestureTeam;
                instance
                  ..onStart = handleScaleStart
                  ..onUpdate = handleScaleUpdate
                  ..onEnd = handleScaleEnd;
              }),
              VerticalDragGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                          VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer(),
                      (VerticalDragGestureRecognizer instance) {
                instance.team ??= scaleGestureTeam;
                // these empty lambdas are necessary to activate this gesture recognizer
                instance.onUpdate = (_) {};
              }),
              HorizontalDragGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                          HorizontalDragGestureRecognizer>(
                      () => HorizontalDragGestureRecognizer(),
                      (HorizontalDragGestureRecognizer instance) {
                instance.team ??= scaleGestureTeam;
                instance.onUpdate = (_) {};
              })
            },
            child: child,
          );

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
            child: options.allowPanningOnScrollingParent
                ? GestureDetector(
                    onTap: _positionedTapController.onTap,
                    onLongPress: _positionedTapController.onLongPress,
                    onTapDown: _positionedTapController.onTapDown,
                    onTapUp: handleOnTapUp,
                    child: scaleGestureDetector(child: _buildMap(size)),
                  )
                : GestureDetector(
                    onScaleStart: handleScaleStart,
                    onScaleUpdate: handleScaleUpdate,
                    onScaleEnd: handleScaleEnd,
                    onTap: _positionedTapController.onTap,
                    onLongPress: _positionedTapController.onLongPress,
                    onTapDown: _positionedTapController.onTapDown,
                    onTapUp: handleOnTapUp,
                    child: _buildMap(size)),
          ),
        ),
      );
    });
  }

  Widget _buildMap(CustomPoint<double> size) {
    print("Map built");
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
  late double _rotationRad;

  double get zoom => _zoom;

  double get rotation => _rotation;

  double get rotationRad => degToRadian(_rotation);

  LatLng? _lastCenter;
  
  late CustomPoint _pixelOrigin;
  CustomPoint get pixelOrigin => _pixelOrigin;

  LatLng get center => getCenter();

  late LatLngBounds _bounds;
  LatLngBounds get bounds => _bounds;

  late Bounds _pixelBounds;
  Bounds get pixelBounds => _pixelBounds;

  // Original size of the map where rotation isn't calculated
  CustomPoint? _originalSize;

  CustomPoint? get originalSize => _originalSize;

  void setOriginalSize(double width, double height) {
    final isCurrSizeNull = _originalSize == null;
    if (isCurrSizeNull ||
        _originalSize!.x != width ||
        _originalSize!.y != height) {
      _originalSize = CustomPoint<double>(width, height);

      _updateSizeByOriginalSizeAndRotation();
    }
  }

  // Extended size of the map where rotation is calculated
  CustomPoint<double>? _size;

  CustomPoint<double> get size => _size ?? const CustomPoint(0.0, 0.0);

  void _updateSizeByOriginalSizeAndRotation() {
    final originalWidth = _originalSize!.x;
    final originalHeight = _originalSize!.y;

    if (_rotation != 0.0) {
      final cosAngle = math.cos(_rotationRad).abs();
      final sinAngle = math.sin(_rotationRad).abs();
      final num width =
          (originalWidth * cosAngle) + (originalHeight * sinAngle);
      final num height =
          (originalHeight * cosAngle) + (originalWidth * sinAngle);

      _size = CustomPoint<double>(width, height);
    } else {
      _size = CustomPoint<double>(originalWidth, originalHeight);
    }

    _pixelOrigin = getNewPixelOrigin(_lastCenter!);
  }

  void _handleMoveEmit(LatLng targetCenter, double targetZoom, bool hasGesture,
      MapEventSource source, String? id) {
    if (source == MapEventSource.flingAnimationController) {
      emitMapEvent(
        MapEventFlingAnimation(
          center: _lastCenter!,
          zoom: _zoom,
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
        ),
      );
    } else if (source == MapEventSource.doubleTapZoomAnimationController) {
      emitMapEvent(
        MapEventDoubleTapZoom(
          center: _lastCenter!,
          zoom: _zoom,
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
        ),
      );
    } else if (source == MapEventSource.scrollWheel) {
      emitMapEvent(
        MapEventScrollWheelZoom(
          center: _lastCenter!,
          zoom: _zoom,
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
        ),
      );
    } else if (source == MapEventSource.onDrag ||
        source == MapEventSource.onMultiFinger) {
      emitMapEvent(
        MapEventMove(
          center: _lastCenter!,
          zoom: _zoom,
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
        ),
      );
    } else if (source == MapEventSource.mapController) {
      emitMapEvent(
        MapEventMove(
          id: id,
          center: _lastCenter!,
          zoom: _zoom,
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
        ),
      );
    } else if (source == MapEventSource.custom) {
      // for custom source, emit move event if zoom or center has changed
      if (targetZoom != _zoom ||
          _lastCenter == null ||
          targetCenter.latitude != _lastCenter!.latitude ||
          targetCenter.longitude != _lastCenter!.longitude) {
        emitMapEvent(
          MapEventMove(
            id: id,
            center: _lastCenter!,
            zoom: _zoom,
            targetCenter: targetCenter,
            targetZoom: targetZoom,
            source: source,
          ),
        );
      }
    }
  }

  void emitMapEvent(MapEvent event) {
    setState(() {
      widget.options.onMapEvent?.call(event);
    });
  }

  bool rotate(
    double degree, {
    bool hasGesture = false,
    required MapEventSource source,
    String? id,
  }) {
    if (degree != _rotation) {
      final oldRotation = _rotation;
      _rotation = degree;
      _updateSizeByOriginalSizeAndRotation();

      // onRotationChanged(_rotation);

      emitMapEvent(
        MapEventRotate(
          id: id,
          currentRotation: oldRotation,
          targetRotation: _rotation,
          center: _lastCenter!,
          zoom: _zoom,
          source: source,
        ),
      );

      return true;
    }

    return false;
  }

  MoveAndRotateResult moveAndRotate(LatLng center, double zoom, double degree,
      {required MapEventSource source, String? id}) {
    final moveSucc =
        move(center, zoom, id: id, source: source);
    final rotateSucc =
        rotate(degree, id: id, source: source);

    if (moveSucc || rotateSucc) {
      setState(() {});
    }

    return MoveAndRotateResult(moveSucc, rotateSucc);
  }

  bool move(LatLng center, double zoom,
      {bool hasGesture = false,
      required MapEventSource source,
      String? id}) {
    zoom = fitZoomToBounds(zoom);
    final mapMoved = center != _lastCenter || zoom != _zoom;

    if (_lastCenter != null && (!mapMoved || !_bounds.isValid)) {
      return false;
    }

    if (options.isOutOfBounds(center)) {
      if (!options.slideOnBoundaries) {
        return false;
      }
      center = options.containPoint(center, _lastCenter ?? center);
    }

    // Try and fit the corners of the map inside the visible area.
    // If it's still outside (so response is null), don't perform a move.
    if (options.maxBounds != null) {
      final adjustedCenter =
          adjustCenterIfOutsideMaxBounds(center, zoom, options.maxBounds!);
      if (adjustedCenter == null) {
        return false;
      } else {
        center = adjustedCenter;
      }
    }

    _handleMoveEmit(center, zoom, hasGesture, source, id);

    _zoom = zoom;
    _lastCenter = center;
    _pixelBounds = getPixelBounds(_zoom);
    _pixelOrigin = getNewPixelOrigin(center);
    setState(() {
      
    });

    if (options.onPositionChanged != null) {
      final mapPosition = MapPosition(
          center: center, bounds: _bounds, zoom: zoom, hasGesture: hasGesture);

      options.onPositionChanged!(mapPosition, hasGesture);
    }

    return true;
  }

  double fitZoomToBounds(double? zoom) {
    zoom ??= _zoom;
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

  LatLng getCenter() {
    if (_lastCenter != null) {
      return _lastCenter!;
    }
    return layerPointToLatLng(_centerLayerPoint);
  }

  LatLngBounds _calculateBounds() {
    print("got bounds");
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

    var zoom = getBoundsZoom(bounds, paddingTotalXY, inside: options.inside);
    zoom = math.min(options.maxZoom, zoom);

    final paddingOffset = (paddingBR - paddingTL) / 2;
    final swPoint = project(bounds.southWest!, zoom);
    final nePoint = project(bounds.northEast!, zoom);
    final center = unproject((swPoint + nePoint) / 2 + paddingOffset, zoom);
    return CenterZoom(
      center: center,
      zoom: zoom,
    );
  }

  double getBoundsZoom(LatLngBounds bounds, CustomPoint<double> padding,
      {bool inside = false}) {
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

    return math.max(min, math.min(max, zoom));
  }

  CustomPoint project(LatLng latlng, [double? zoom]) {
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

  CustomPoint get _centerLayerPoint {
    return size / 2;
  }

  double getZoomScale(double toZoom, double? fromZoom) {
    final crs = options.crs;
    fromZoom = fromZoom ?? _zoom;
    return crs.scale(toZoom) / crs.scale(fromZoom);
  }

  double getScaleZoom(double scale, double? fromZoom) {
    final crs = options.crs;
    fromZoom = fromZoom ?? _zoom;
    return crs.zoom(scale * crs.scale(fromZoom)) as double;
  }

  Bounds? getPixelWorldBounds(double? zoom) {
    return options.crs.getProjectedBounds(zoom ?? _zoom);
  }

  Offset getOffsetFromOrigin(LatLng pos) {
    final delta = project(pos) - _pixelOrigin;
    return Offset(delta.x.toDouble(), delta.y.toDouble());
  }

  CustomPoint getNewPixelOrigin(LatLng center, [double? zoom]) {
    final viewHalf = size / 2.0;
    return (project(center, zoom) - viewHalf).round();
  }

  Bounds getPixelBounds(double zoom) {
    print("pixel bounds");
    final mapZoom = zoom;
    final scale = getZoomScale(mapZoom, zoom);
    final pixelCenter = project(center, zoom).floor();
    final halfSize = size / (scale * 2);
    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

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

  // This will convert a latLng to a position that we could use with a widget
  // outside of FlutterMap layer space. Eg using a Positioned Widget.
  CustomPoint latLngToScreenPoint(LatLng latLng) {
    final nonRotatedPixelOrigin =
        (project(getCenter(), zoom) - originalSize! / 2.0).round();

    var point = options.crs.latLngToPoint(latLng, zoom);

    final mapCenter = options.crs.latLngToPoint(center, zoom);

    if (rotation != 0.0) {
      point = rotatePoint(mapCenter, point, counterRotation: false);
    }

    return point - nonRotatedPixelOrigin;
  }

  LatLng? pointToLatLng(CustomPoint localPoint) {
    if (originalSize == null) {
      return null;
    }

    final width = originalSize!.x;
    final height = originalSize!.y;

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
