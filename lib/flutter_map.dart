library flutter_map;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/geo/crs/crs.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:flutter_map/src/plugins/plugin.dart';
import 'package:latlong/latlong.dart';

export 'src/core/center_zoom.dart';
export 'src/core/point.dart';
export 'src/geo/crs/crs.dart';
export 'src/geo/latlng_bounds.dart';
export 'src/layer/circle_layer.dart';
export 'src/layer/group_layer.dart';
export 'src/layer/layer.dart';
export 'src/layer/marker_layer.dart';
export 'src/layer/mbtiles/mbtiles_image_provider.dart';
export 'src/layer/overlay_image_layer.dart';
export 'src/layer/polygon_layer.dart';
export 'src/layer/polyline_layer.dart';
export 'src/layer/tile_layer.dart';
export 'src/plugins/plugin.dart';

class FlutterMap extends StatefulWidget {
  /// A set of layers' options to used to create the layers on the map
  ///
  /// Usually a list of [TileLayerOptions], [MarkerLayerOptions] and
  /// [PolylineLayerOptions].
  final List<LayerOptions> layers;

  /// [MapOptions] to create a [MapState] with
  ///
  /// This property must not be null.
  final MapOptions options;

  /// A [MapController], used to control the map
  final MapControllerImpl _mapController;

  FlutterMap({
    Key key,
    @required this.options,
    this.layers,
    MapController mapController,
  })  : _mapController = mapController ?? MapController(),
        super(key: key);

  @override
  FlutterMapState createState() => FlutterMapState(_mapController);
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
  LatLngBounds get bounds;
  double get zoom;

  factory MapController() => MapControllerImpl();
}

typedef void TapCallback(LatLng point);
typedef void LongPressCallback(LatLng point);
typedef void PositionCallback(MapPosition position, bool hasGesture, bool isUserGesture);

class MapOptions {
  final Crs crs;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final bool debug;
  final bool interactive;
  final TapCallback onTap;
  final LongPressCallback onLongPress;
  final PositionCallback onPositionChanged;
  final List<MapPlugin> plugins;
  LatLng center;
  LatLng swPanBoundary;
  LatLng nePanBoundary;

  MapOptions({
    this.crs = const Epsg3857(),
    this.center,
    this.zoom = 13.0,
    this.minZoom,
    this.maxZoom,
    this.debug = false,
    this.interactive = true,
    this.onTap,
    this.onLongPress,
    this.onPositionChanged,
    this.plugins = const [],
    this.swPanBoundary,
    this.nePanBoundary,
  }) {
    center ??= LatLng(50.5, 30.51);
    assert(!isOutOfBounds(center)); //You cannot start outside pan boundary
  }

  //if there is a pan boundary, do not cross
  bool isOutOfBounds(LatLng center) {
    if (swPanBoundary != null && nePanBoundary != null) {
      if (center == null) {
        return true;
      } else if (center.latitude < swPanBoundary.latitude ||
          center.latitude > nePanBoundary.latitude) {
        return true;
      } else if (center.longitude < swPanBoundary.longitude ||
          center.longitude > nePanBoundary.longitude) {
        return true;
      }
    }
    return false;
  }
}

class FitBoundsOptions {
  final EdgeInsets padding;
  final double maxZoom;
  final double zoom;

  const FitBoundsOptions({
    this.padding = const EdgeInsets.all(0.0),
    this.maxZoom = 17.0,
    this.zoom,
  });
}

class MapPosition {
  final LatLng center;
  final LatLngBounds bounds;
  final double zoom;
  final bool hasGesture;
  MapPosition({this.center, this.bounds, this.zoom, this.hasGesture = false});
}
