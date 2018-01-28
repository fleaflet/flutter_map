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
  double zoom = 13.0;

  MapState(this.options);

  Point size;

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
}
