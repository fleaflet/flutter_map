import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/center_zoom.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/core/util.dart';
import 'package:latlong/latlong.dart';

class MapControllerImpl implements MapController {
  Completer<Null> _readyCompleter = Completer<Null>();
  MapState _state;

  Future<Null> get onReady => _readyCompleter.future;

  set state(MapState state) {
    _state = state;
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
  }

  void move(LatLng center, double zoom, {bool hasGesture = false}) {
    _state.move(center, zoom, hasGesture: hasGesture);
  }

  void fitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions options =
        const FitBoundsOptions(padding: const Point(24.0, 24.0)),
  }) {
    _state.fitBounds(bounds, options);
  }

  bool get ready => _state != null;

  LatLng get center => _state.center;

  LatLngBounds get bounds => _state.bounds;

  double get zoom => _state.zoom;
}

class MapState {
  final MapOptions options;
  final StreamController<Null> _onMoveSink;

  double _zoom;

  double get zoom => _zoom;

  LatLng _lastCenter;
  LatLngBounds _lastBounds;
  Point _pixelOrigin;
  bool _initialized = false;

  MapState(this.options) : _onMoveSink = StreamController.broadcast();

  Point _size;

  Stream<Null> get onMoved => _onMoveSink.stream;

  Point get size => _size;

  set size(Point s) {
    _size = s;
    _pixelOrigin = getNewPixelOrigin(_lastCenter);
    if (!_initialized) {
      _init();
      _initialized = true;
    }
  }

  LatLng get center => getCenter() ?? options.center;

  LatLngBounds get bounds => getBounds();

  void _init() {
    _zoom = options.zoom;
    move(options.center, zoom);
  }

  void dispose() {
    _onMoveSink.close();
  }

  void move(LatLng center, double zoom, {hasGesture = false}) {
    zoom = _fitZoomToBounds(zoom);
    final mapMoved = center != _lastCenter || zoom != _zoom;

    if (!mapMoved || options.isOutOfBounds(center)) {
      return;
    }

    _zoom = zoom;
    _lastCenter = center;
    _lastBounds = _calculateBounds();
    _pixelOrigin = getNewPixelOrigin(center);
    _onMoveSink.add(null);

    if (options.onPositionChanged != null) {
      options.onPositionChanged(MapPosition(
        center: center,
        bounds: bounds,
        zoom: zoom,
      ), hasGesture);
    }
  }

  double _fitZoomToBounds(double zoom) {
    if (zoom == null) {
      zoom = _zoom;
    }
    // Abide to min/max zoom
    if (options.maxZoom != null) {
      zoom = (zoom > options.maxZoom) ? options.maxZoom : zoom;
    }
    if (options.minZoom != null) {
      zoom = (zoom < options.minZoom) ? options.minZoom : zoom;
    }
    return zoom;
  }

  void fitBounds(LatLngBounds bounds, FitBoundsOptions options) {
    if (!bounds.isValid) {
      throw ("Bounds are not valid.");
    }
    var target = _getBoundsCenterZoom(bounds, options);
    move(target.center, target.zoom);
  }

  LatLng getCenter() {
    if (_lastCenter != null) {
      return _lastCenter;
    }
    return layerPointToLatLng(_centerLayerPoint);
  }

  LatLngBounds getBounds() {
    if (_lastBounds != null) {
      return _lastBounds;
    }

    return _calculateBounds();
  }

  LatLngBounds _calculateBounds() {
    var bounds = getPixelBounds(zoom);
    return LatLngBounds(
      unproject(bounds.bottomLeft),
      unproject(bounds.topRight),
    );
  }

  CenterZoom _getBoundsCenterZoom(
      LatLngBounds bounds, FitBoundsOptions options) {
    var paddingTL = options.padding;
    var paddingBR = options.padding;

    var zoom = getBoundsZoom(bounds, paddingTL + paddingBR, inside: false);
    zoom = math.min(options.maxZoom, zoom);

    var paddingOffset = (paddingBR - paddingTL) / 2;
    var swPoint = project(bounds.southWest, zoom);
    var nePoint = project(bounds.northEast, zoom);
    var center = unproject((swPoint + nePoint) / 2 + paddingOffset, zoom);
    return CenterZoom(
      center: center,
      zoom: zoom,
    );
  }

  double getBoundsZoom(LatLngBounds bounds, Point<double> padding,
      {bool inside = false}) {
    var zoom = this.zoom ?? 0.0;
    var min = this.options.minZoom ?? 0.0;
    var max = this.options.maxZoom ?? double.infinity;
    var nw = bounds.northWest;
    var se = bounds.southEast;
    var size = this.size - padding;
    var boundsSize = Bounds(project(se, zoom), project(nw, zoom)).size;
    var scaleX = size.x / boundsSize.x;
    var scaleY = size.y / boundsSize.y;
    var scale = inside ? math.max(scaleX, scaleY) : math.min(scaleX, scaleY);

    zoom = getScaleZoom(scale, zoom);

    return math.max(min, math.min(max, zoom));
  }

  Point project(LatLng latlng, [double zoom]) {
    if (zoom == null) {
      zoom = _zoom;
    }
    return options.crs.latLngToPoint(latlng, zoom);
  }

  LatLng unproject(Point point, [double zoom]) {
    if (zoom == null) {
      zoom = _zoom;
    }
    return options.crs.pointToLatLng(point, zoom);
  }

  LatLng layerPointToLatLng(Point point) {
    return unproject(point);
  }

  LatLng offsetToLatLng(
      Offset rawOffset, Offset boxOffset, double width, double height) {
    var deltaOffset = rawOffset - boxOffset;
    var localPoint = Point(deltaOffset.dx, deltaOffset.dy);
    var localPointCenterDistance =
        Point((width / 2) - localPoint.x, (height / 2) - localPoint.y);
    var mapCenter = project(center);
    var point = mapCenter - localPointCenterDistance;
    return unproject(point);
  }

  Offset latlngToOffset(LatLng point) {
    var pos = project(point);
    pos = pos.multiplyBy(getZoomScale(zoom, zoom)) - getPixelOrigin();
    return Offset(pos.x.toDouble(), pos.y.toDouble());
  }

  Point get _centerLayerPoint {
    return size / 2;
  }

  double getZoomScale(double toZoom, double fromZoom) {
    var crs = options.crs;
    fromZoom = fromZoom == null ? _zoom : fromZoom;
    return crs.scale(toZoom) / crs.scale(fromZoom);
  }

  double getScaleZoom(double scale, double fromZoom) {
    var crs = options.crs;
    fromZoom = fromZoom == null ? _zoom : fromZoom;
    return crs.zoom(scale * crs.scale(fromZoom));
  }

  Bounds getPixelWorldBounds(double zoom) {
    return options.crs.getProjectedBounds(zoom == null ? _zoom : zoom);
  }

  Point getPixelOrigin() {
    return _pixelOrigin;
  }

  Point getNewPixelOrigin(LatLng center, [double zoom]) {
    var viewHalf = this.size / 2.0;
    return (this.project(center, zoom) - viewHalf).round();
  }

  Bounds getPixelBounds(double zoom) {
    var mapZoom = zoom;
    var scale = getZoomScale(mapZoom, zoom);
    var pixelCenter = project(center, zoom).floor();
    Point<num> halfSize = size / (scale * 2);
    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

  double getMetersPerPixel(double latitude) {
    double pixelsPerTile = 256.0;
    double numTiles = math.pow(2, this.zoom).toDouble();
    double metersPerTile =
        math.cos(degToRadian(latitude)) * EARTH_CIRCUMFERENCE_METERS / numTiles;
    return metersPerTile / pixelsPerTile;
  }
}
