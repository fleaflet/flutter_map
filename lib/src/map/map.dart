import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/map/map_state_widget.dart';
import 'package:latlong2/latlong.dart';

class MapControllerImpl implements MapController {
  final Completer<void> _readyCompleter = Completer<void>();
  final StreamController<MapEvent> _mapEventSink = StreamController.broadcast();
  @override
  StreamSink<MapEvent> get mapEventSink => _mapEventSink.sink;

  @override
  Future<void> get onReady => _readyCompleter.future;

  @override
  void dispose() {
    _mapEventSink.close();
  }

  late final MapState _state;
  @override
  set state(MapState state) {
    _state = state;
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
  }

  @override
  MoveAndRotateResult moveAndRotate(LatLng center, double zoom, double degree,
      {String? id}) {
    return _state.moveAndRotate(center, zoom, degree,
        source: MapEventSource.mapController, id: id);
  }

  @override
  bool move(LatLng center, double zoom, {String? id}) {
    return _state.move(center, zoom,
        id: id, source: MapEventSource.mapController);
  }

  @override
  void fitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions? options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  }) {
    _state.fitBounds(bounds, options!);
  }

  @override
  CenterZoom centerZoomFitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions? options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  }) {
    return _state.centerZoomFitBounds(bounds, options!);
  }

  @override
  LatLng get center => _state.center;

  @override
  LatLngBounds? get bounds => _state.bounds;

  @override
  double get zoom => _state.zoom;

  @override
  double get rotation => _state.rotation;

  @override
  bool rotate(double degree, {String? id}) {
    return _state.rotate(degree, id: id, source: MapEventSource.mapController);
  }

  @override
  LatLng? pointToLatLng(CustomPoint localPoint) {
    if (_state.originalSize == null) {
      return null;
    }

    final width = _state.originalSize!.x;
    final height = _state.originalSize!.y;

    final localPointCenterDistance =
        CustomPoint((width / 2) - localPoint.x, (height / 2) - localPoint.y);
    final mapCenter =
        _state.options.crs.latLngToPoint(_state.center, _state.zoom);

    var point = mapCenter - localPointCenterDistance;

    if (_state.rotation != 0.0) {
      point = rotatePoint(mapCenter, point);
    }

    return _state.options.crs.pointToLatLng(point, _state.zoom);
  }

  CustomPoint<num> rotatePoint(
      CustomPoint<num> mapCenter, CustomPoint<num> point) {
    final m = Matrix4.identity()
      ..translate(mapCenter.x.toDouble(), mapCenter.y.toDouble())
      ..rotateZ(-_state.rotationRad)
      ..translate(-mapCenter.x.toDouble(), -mapCenter.y.toDouble());

    final tp = MatrixUtils.transformPoint(
        m, Offset(point.x.toDouble(), point.y.toDouble()));

    return CustomPoint(tp.dx, tp.dy);
  }

  @override
  Stream<MapEvent> get mapEventStream => _mapEventSink.stream;
}

class MapState {
  MapOptions options;
  final ValueChanged<double> onRotationChanged;
  final StreamController<void> _onMoveSink;
  final StreamSink<MapEvent> _mapEventSink;

  double _zoom;
  double _rotation;
  double _rotationRad;

  double get zoom => _zoom;
  double get rotation => _rotation;

  set rotation(double rotation) {
    _rotation = rotation;
    _rotationRad = degToRadian(rotation);
  }

  double get rotationRad => _rotationRad;

  LatLng? _lastCenter;
  LatLngBounds? _lastBounds;
  Bounds? _lastPixelBounds;
  late CustomPoint _pixelOrigin;
  bool _initialized = false;

  MapState(this.options, this.onRotationChanged, this._mapEventSink)
      : _rotation = options.rotation,
        _rotationRad = degToRadian(options.rotation),
        _zoom = options.zoom,
        _onMoveSink = StreamController.broadcast();

  Stream<void> get onMoved => _onMoveSink.stream;

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

      // rebuild layers if screen size has been changed
      if (!isCurrSizeNull) {
        _onMoveSink.add(null);
      }
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

    if (!_initialized) {
      _init();
      _initialized = true;
    }

    _pixelOrigin = getNewPixelOrigin(_lastCenter!);
  }

  LatLng get center => getCenter();

  LatLngBounds get bounds => getBounds();

  Bounds get pixelBounds => getLastPixelBounds();

  void _init() {
    if (options.bounds != null) {
      fitBounds(options.bounds!, options.boundsOptions);
    } else {
      move(options.center, zoom, source: MapEventSource.initialization);
    }
  }

  // Check if we've just got a new size constraints. Initially a layoutBuilder
  // May not be able to calculate a size, and end up with 0,0
  bool hasLateSize(BoxConstraints constraints) {
    if (options.bounds != null &&
        originalSize != null &&
        originalSize!.x == 0.0 &&
        constraints.maxWidth != 0.0) {
      return true;
    }
    return false;
  }

  // If we've just calculated a size, we may want to call some methods that
  // rely on it, like fitBounds. Add any others here.
  void initIfLateSize() {
    if (options.bounds != null) {
      fitBounds(options.bounds!, options.boundsOptions);
    }
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
    _mapEventSink.add(event);
  }

  void dispose() {
    _onMoveSink.close();
    _mapEventSink.close();
  }

  void rebuildLayers() {
    _onMoveSink.add(null);
  }

  bool rotate(
    double degree, {
    bool hasGesture = false,
    bool callOnMoveSink = true,
    required MapEventSource source,
    String? id,
  }) {
    if (degree != _rotation) {
      final oldRotation = _rotation;
      rotation = degree;
      _updateSizeByOriginalSizeAndRotation();

      onRotationChanged(_rotation);

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

      if (callOnMoveSink) {
        _onMoveSink.add(null);
      }

      return true;
    }

    return false;
  }

  MoveAndRotateResult moveAndRotate(LatLng center, double zoom, double degree,
      {required MapEventSource source, String? id}) {
    final moveSucc =
        move(center, zoom, id: id, source: source, callOnMoveSink: false);
    final rotateSucc =
        rotate(degree, id: id, source: source, callOnMoveSink: false);

    if (moveSucc || rotateSucc) {
      _onMoveSink.add(null);
    }

    return MoveAndRotateResult(moveSucc, rotateSucc);
  }

  bool move(LatLng center, double zoom,
      {bool hasGesture = false,
      bool callOnMoveSink = true,
      required MapEventSource source,
      String? id}) {
    zoom = fitZoomToBounds(zoom);
    final mapMoved = center != _lastCenter || zoom != _zoom;

    if (_lastCenter != null && (!mapMoved || !bounds.isValid)) {
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
    _lastPixelBounds = getPixelBounds(_zoom);
    _lastBounds = _calculateBounds();
    _pixelOrigin = getNewPixelOrigin(center);
    if (callOnMoveSink) {
      _onMoveSink.add(null);
    }

    if (options.onPositionChanged != null) {
      final mapPosition = MapPosition(
          center: center, bounds: bounds, zoom: zoom, hasGesture: hasGesture);

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

  LatLngBounds getBounds() {
    if (_lastBounds != null) {
      return _lastBounds!;
    }

    return _calculateBounds();
  }

  Bounds getLastPixelBounds() {
    if (_lastPixelBounds != null) {
      return _lastPixelBounds!;
    }

    return getPixelBounds(zoom);
  }

  LatLngBounds _calculateBounds() {
    final bounds = getLastPixelBounds();
    return LatLngBounds(
      unproject(bounds.bottomLeft),
      unproject(bounds.topRight),
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
    size = CustomPoint(math.max(0, size.x), math.max(0, size.y));
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

  CustomPoint getPixelOrigin() {
    return _pixelOrigin;
  }

  CustomPoint getNewPixelOrigin(LatLng center, [double? zoom]) {
    final viewHalf = size / 2.0;
    return (project(center, zoom) - viewHalf).round();
  }

  Bounds getPixelBounds(double zoom) {
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

  static MapState? maybeOf(BuildContext context, {bool nullOk = false}) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<MapStateInheritedWidget>();
    if (nullOk || widget != null) {
      return widget?.mapState;
    }
    throw FlutterError(
        'MapState.of() called with a context that does not contain a FlutterMap.');
  }
}
