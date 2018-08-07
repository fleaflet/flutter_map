library flutter_map;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';

import 'flutter_map.dart';
import 'src/core/point.dart';
import 'src/geo/crs/crs.dart';
import 'src/map/flutter_map_state.dart';
import 'src/map/map.dart';
import 'src/plugins/plugin.dart';
export 'src/plugins/plugin.dart';
export 'src/layer/layer.dart';
export 'src/layer/tile_layer.dart';
export 'src/layer/marker_layer.dart';
export 'src/layer/polyline_layer.dart';
export 'src/geo/crs/crs.dart';
export 'src/geo/latlng_bounds.dart';
export 'src/core/point.dart';

class FlutterMap extends StatefulWidget {
  /// A set of layers' options to used to create the layers on the map
  ///
  /// Usually a list of [TileLayerOptions], [MarkerLayerOptions] and
  /// [PolylineLayerOptions].
  final List<LayerOptions> layers;

  /// [MapOptions] to create a [MapState] with
  ///
  /// Please note: If both [options] and [mapState] are set, mapState's options
  /// will take precedence, but the [:onTap:] callback of the options will be
  /// used!
  final MapOptions options;

  /// A [MapController], used to control the map
  final MapControllerImpl _mapController;

  FlutterMap({
    Key key,
    this.options,
    this.layers,
    MapController mapController,
  })  : _mapController = mapController ?? new MapController(),
        super(key: key);

  FlutterMapState createState() => new FlutterMapState(_mapController);
}

abstract class MapController {
  /// Moves the map to a specific location and zoom level
  void move(LatLng center, double zoom);
  void fitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions options,
  });
  bool get ready;
  Future<Null> get onReady;
  LatLng get center;
  double get zoom;

  factory MapController() => new MapControllerImpl();
}

typedef TapCallback(LatLng point);
typedef PositionCallback(MapPosition position);

class MapOptions {
  final Crs crs;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final List<LayerOptions> layers;
  final bool debug;
  final bool interactive;
  final TapCallback onTap;
  final PositionCallback onPositionChanged;
  final List<MapPlugin> plugins;
  LatLng center;
  LatLng swPanBoundary;
  LatLng nePanBoundary;

  MapOptions({
    this.crs: const Epsg3857(),
    this.center,
    this.zoom = 13.0,
    this.minZoom,
    this.maxZoom,
    this.layers,
    this.debug = false,
    this.interactive = true,
    this.onTap,
    this.onPositionChanged,
    this.plugins = const [],
    this.swPanBoundary,
    this.nePanBoundary,
  }) {
    if (center == null) center = new LatLng(50.5, 30.51);
    assert(!isOutOfBounds(center)); //You cannot start outside pan boundary
  }

  //if there is a pan boundary, do not cross
  bool isOutOfBounds(LatLng center) {
    if (this.swPanBoundary != null && this.nePanBoundary != null) {
      if (center.latitude < this.swPanBoundary.latitude ||
          center.latitude > this.nePanBoundary.latitude) {
        return true;
      } else if (center.longitude < this.swPanBoundary.longitude ||
          center.longitude > this.nePanBoundary.longitude) {
        return true;
      }
    }
    return false;
  }
}

class FitBoundsOptions {
  final Point<double> padding;
  final double maxZoom;
  final double zoom;

  const FitBoundsOptions({
    this.padding = const Point<double>(0.0, 0.0),
    this.maxZoom = 17.0,
    this.zoom,
  });
}

class MapPosition {
  final LatLng center;
  final double zoom;
  MapPosition({this.center, this.zoom});
}
