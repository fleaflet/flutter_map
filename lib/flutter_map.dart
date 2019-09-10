library flutter_map;

import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/geo/crs/crs.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:flutter_map/src/plugins/plugin.dart';
import 'package:latlong/latlong.dart';

export 'package:flutter_map/src/core/point.dart';
export 'package:flutter_map/src/geo/crs/crs.dart';
export 'package:flutter_map/src/geo/latlng_bounds.dart';
export 'package:flutter_map/src/layer/circle_layer.dart';
export 'package:flutter_map/src/layer/group_layer.dart';
export 'package:flutter_map/src/layer/layer.dart';
export 'package:flutter_map/src/layer/marker_layer.dart';
export 'package:flutter_map/src/layer/overlay_image_layer.dart';
export 'package:flutter_map/src/layer/polygon_layer.dart';
export 'package:flutter_map/src/layer/polyline_layer.dart';
export 'package:flutter_map/src/layer/tile_layer.dart';
export 'package:flutter_map/src/layer/tile_provider/mbtiles_image_provider.dart';
export 'package:flutter_map/src/layer/tile_provider/tile_provider.dart';
export 'package:flutter_map/src/plugins/plugin.dart';

/// Renders a map composed of a list of layers powered by [LayerOptions].
///
/// Use a [MapController] to interact programmatically with the map.
///
/// Through [MapOptions] map's callbacks and properties can be defined.
class FlutterMap extends StatefulWidget {
  /// A set of layers' options to used to create the layers on the map.
  ///
  /// Usually a list of [TileLayerOptions], [MarkerLayerOptions] and
  /// [PolylineLayerOptions].
  final List<LayerOptions> layers;

  /// [MapOptions] to create a [MapState] with.
  ///
  /// This property must not be null.
  final MapOptions options;

  /// A [MapController], used to control the map.
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

/// Controller to programmatically interact with [FlutterMap].
///
/// It allows for map movement through [move], rotation through [rotate]
/// and to fit the map bounds with [fitBounds].
///
/// It also provides current map properties.
abstract class MapController {
  /// Moves the map to a specific location and zoom level
  void move(LatLng center, double zoom);

  /// Sets the map rotation to a certain degrees angle (in decimal).
  void rotate(double degree);

  /// Fits the map bounds. Optional constraints can be defined
  /// through the [options] parameter.
  void fitBounds(LatLngBounds bounds, {FitBoundsOptions options});

  bool get ready;

  Future<Null> get onReady;

  LatLng get center;

  LatLngBounds get bounds;

  double get zoom;

  ValueChanged<double> onRotationChanged;

  factory MapController() => MapControllerImpl();
}

typedef void TapCallback(LatLng point);
typedef void LongPressCallback(LatLng point);
typedef void PositionCallback(MapPosition position, bool hasGesture);

/// Allows you to provide your map's starting properties for [zoom], [rotation]
/// and [center].
/// Zoom, pan boundary and interactivity constraints can be specified here too.
///
/// Callbacks for [onTap], [onLongPress] and [onPositionChanged] can be
/// registered here.
///
/// Through [crs] the Coordinate Reference System can be
/// defined, it defaults to [Epsg3857].
///
/// Checks if a coordinate is outside of the map's
/// defined boundaries.
class MapOptions {
  final Crs crs;
  final double zoom;
  final double rotation;
  final double minZoom;
  final double maxZoom;
  @deprecated
  final bool debug; // TODO no usage outside of constructor. Marked for removal?
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
    this.rotation = 0.0,
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

/// Position's type for [PositionCallback].
class MapPosition {
  final LatLng center;
  final LatLngBounds bounds;
  final double zoom;
  final bool hasGesture;

  MapPosition({this.center, this.bounds, this.zoom, this.hasGesture = false});
}

/// Extension that prevents any tiles outside the bounds from ever being
/// displayed, regardless of zoom level
class AdaptiveBoundariesMapOptions extends MapOptions {
  static const double initialZoom = 13;

  final Size screenSize;
  final MapController controller;

  AdaptiveBoundariesMapOptions({
    @required this.screenSize,
    @required this.controller,
    @required LatLng center,
    @required double minZoom,
    @required double maxZoom,
    @required LatLng swPanBoundary,
    @required LatLng nePanBoundary,
  }) : super(
          center: center,
          minZoom: minZoom,
          maxZoom: maxZoom,
          swPanBoundary: swPanBoundary,
          nePanBoundary: nePanBoundary,
          zoom: initialZoom,
        );

  /// More conservative calculation which accounts for screen size
  @override
  bool isOutOfBounds(LatLng point) {
    final corners = _getCornerCoordinates(point);
    return corners.any(super.isOutOfBounds);
  }

  Iterable<LatLng> _getCornerCoordinates(LatLng point) sync* {
    final halfScreenHeight = _calculateScreenWidthInDegrees() / 2;
    final halfScreenWidth = _calculateScreenHeightInDegrees() / 2;
    const signs = [-1, 1];
    for (var latSign in signs) {
      for (var lonSign in signs) {
        yield LatLng(point.latitude + latSign * halfScreenHeight,
            point.longitude + lonSign * halfScreenWidth);
      }
    }
  }

  double _calculateScreenWidthInDegrees() {
    final zoom = _getControllerZoom();
    final degreesPerPixel = 360 / pow(2, zoom + 8);
    return screenSize.width * degreesPerPixel;
  }

  double _calculateScreenHeightInDegrees() =>
      screenSize.height * 180 / pow(2, _getControllerZoom() + 8) * 4 / 3;

  double _getControllerZoom() =>
      controller.ready ? controller.zoom : initialZoom;
}
