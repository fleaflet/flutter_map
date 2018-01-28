import 'package:latlong/latlong.dart';
import 'package:leaflet_flutter/leaflet_flutter.dart';
import 'package:leaflet_flutter/src/core/bounds.dart';
import 'package:leaflet_flutter/src/core/point.dart';
import 'package:leaflet_flutter/src/geo/crs/crs.dart';

class MapOptions {
  final Crs crs;
  final LatLng center;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final List<LayerOptions> layers;

  MapOptions({
    this.crs: const Epsg3857(),
    this.center,
    this.zoom,
    this.minZoom,
    this.maxZoom,
    this.layers,
  });
}

class MapState {
  final MapOptions options;
  double zoom = 1.0;
  LatLng _lastCenter;
  Point _pixelOrigin;

  MapState(this.options);

  Point _size;

  set size(Point s) {
    _size = s;
    _init();
  }

  Point get size => _size;

  void _init() {
    _move(center, zoom);
  }

  void _move(LatLng center, double zoom, [data]) {
    if (zoom == null) {
      zoom = this.zoom;
    }

//    var zoomChanged = this.zoom != zoom;
    this.zoom = zoom;
    this._lastCenter = center;
    this._pixelOrigin = this.getNewPixelOrigin(center);
    // todo: events
  }

  LatLng get center {
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
