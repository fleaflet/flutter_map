import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_map/src/core/center_zoom.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';

class MapControllerImpl implements MapController {
  MapState state;

  void move(LatLng center, double zoom) {
    state.move(center, zoom);
  }

  void fitBounds(LatLngBounds bounds, FitBoundsOptions options) {
    state.fitBounds(bounds, options);
  }
}

class MapState {
  final MapOptions options;
  final StreamController<Null> _onMoveSink;

  double _zoom;
  double get zoom => _zoom;

  LatLng _lastCenter;
  Point _pixelOrigin;
  bool _initialized = false;

  MapState(this.options) : _onMoveSink = new StreamController.broadcast();

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

  void _init() {
    _zoom = options.zoom;
    move(options.center, zoom);
  }

  void dispose() {
    _onMoveSink.close();
  }

  void move(LatLng center, double zoom) {
    if (zoom == null) {
      zoom = _zoom;
    }

    _zoom = zoom;
    _lastCenter = center;
    _pixelOrigin = getNewPixelOrigin(center);
    _onMoveSink.add(null);
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
    return new CenterZoom(
      center: center,
      zoom: zoom,
    );
  }

  double getBoundsZoom(LatLngBounds bounds, Point<double> padding,
      {bool inside = false}) {
    var zoom = this.zoom ?? 0.0;
    var min = this.options.minZoom ?? 0.0;
    var max = this.options.maxZoom ?? double.INFINITY;
    var nw = bounds.northWest;
    var se = bounds.southEast;
    var size = this.size - padding;
    var boundsSize = new Bounds(project(se, zoom), project(nw, zoom)).size;
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
}

