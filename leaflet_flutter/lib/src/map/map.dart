import 'dart:async';

import 'package:latlong/latlong.dart';
import 'package:leaflet_flutter/leaflet_flutter.dart';
import 'package:leaflet_flutter/src/core/bounds.dart';
import 'package:leaflet_flutter/src/core/point.dart';
import 'package:leaflet_flutter/src/geo/crs/crs.dart';

class MapOptions {
  final Crs crs;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final List<LayerOptions> layers;
  final bool debug;
  LatLng center;

  MapOptions({
    this.crs: const Epsg3857(),
    this.center,
    this.zoom = 13.0,
    this.minZoom,
    this.maxZoom,
    this.layers,
    this.debug = false,
  }) {
    if (center == null) center = new LatLng(50.5, 30.51);
  }
}

class MapState {
  final MapOptions options;
  final StreamController<Null> _onMovedSink;
  double zoom;
  LatLng _lastCenter;
  Point _pixelOrigin;
  Point panOffset = new Point(0.0, 0.0);
  bool _initialized = false;

  MapState(this.options) : _onMovedSink = new StreamController.broadcast();

  Point _size;

  Stream<Null> get onMoved => _onMovedSink.stream;

  set size(Point s) {
    _size = s;
    if (!_initialized) {
      _init();
      _initialized = true;
    }
  }

  Point get size => _size;

  LatLng get center => getCenter() ?? options.center;

  void _init() {
    this.zoom = options.zoom;
    move(options.center, zoom);
  }

  void move(LatLng center, double zoom, [data]) {
    if (zoom == null) {
      zoom = this.zoom;
    }

    this.zoom = zoom;
    this._lastCenter = center;
    this._pixelOrigin = this.getNewPixelOrigin(center);
    _onMovedSink.add(null);
  }

  void panBy(Point offset) {
    panOffset += offset;
  }

  void panTo(Point offset) {
    panOffset = offset;
  }

  LatLng getCenter() {
    if (_lastCenter != null) {
      return _lastCenter;
    }
    return layerPointToLatLng(_centerLayerPoint);
  }

  Point project(LatLng latlng, [double zoom]) {
    if (zoom == null) {
      zoom = this.zoom;
    }
    return options.crs.latLngToPoint(latlng, zoom);
  }

  LatLng unproject(Point point, [double zoom]) {
    if (zoom == null) {
      zoom = this.zoom;
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
    var crs = this.options.crs;
    fromZoom = fromZoom == null ? this.zoom : fromZoom;
    return crs.scale(toZoom) / crs.scale(fromZoom);
  }

  Bounds getPixelWorldBounds(double zoom) {
    return options.crs.getProjectedBounds(zoom == null ? this.zoom : zoom);
  }

  Point getPixelOrigin() {
    return _pixelOrigin;
  }

  Point getNewPixelOrigin(LatLng center, [double zoom]) {
    var viewHalf = this.size / 2;
    return (this.project(center, zoom) - viewHalf).round();
  }
}
