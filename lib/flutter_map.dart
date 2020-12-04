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

  /// A set of layers' widgets to used to create the layers on the map.
  final List<Widget> children;

  /// [MapOptions] to create a [MapState] with.
  ///
  /// This property must not be null.
  final MapOptions options;

  /// A [MapController], used to control the map.
  final MapControllerImpl _mapController;

  FlutterMap({
    Key key,
    @required this.options,
    this.layers = const [],
    this.children = const [],
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

  Stream<MapPosition> get position;

  factory MapController() => MapControllerImpl();
}

typedef TapCallback = void Function(LatLng point);
typedef LongPressCallback = void Function(LatLng point);
typedef PositionCallback = void Function(MapPosition position, bool hasGesture);

/// Allows you to provide your map's starting properties for [zoom], [rotation]
/// and [center]. Alternatively you can provide [bounds] instead of [center].
/// If both, [center] and [bounds] are provided, bounds will take preference
/// over [center].
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
///
/// If you download offline tiles dynamically, you can set [adaptiveBoundaries]
/// to true (make sure to pass [screenSize] and an external [controller]), which
/// will enforce panning/zooming to ensure there is never a need to display
/// tiles outside the boundaries set by [swPanBoundary] and [nePanBoundary].
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
  final bool slideOnBoundaries;
  final Size screenSize;
  final bool adaptiveBoundaries;
  final MapController controller;
  LatLng center;
  LatLngBounds bounds;
  FitBoundsOptions boundsOptions;
  LatLng swPanBoundary;
  LatLng nePanBoundary;

  _SafeArea _safeAreaCache;
  double _safeAreaZoom;

  MapOptions({
    this.crs = const Epsg3857(),
    this.center,
    this.bounds,
    this.boundsOptions = const FitBoundsOptions(),
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
    this.slideOnBoundaries = false,
    this.adaptiveBoundaries = false,
    this.screenSize,
    this.controller,
    this.swPanBoundary,
    this.nePanBoundary,
  }) {
    center ??= LatLng(50.5, 30.51);
    _safeAreaZoom = zoom;
    assert(slideOnBoundaries ||
        !isOutOfBounds(center)); //You cannot start outside pan boundary
    assert(!adaptiveBoundaries || screenSize != null,
        'screenSize must be set in order to enable adaptive boundaries.');
    assert(!adaptiveBoundaries || controller != null,
        'controller must be set in order to enable adaptive boundaries.');
  }

  //if there is a pan boundary, do not cross
  bool isOutOfBounds(LatLng center) {
    if (adaptiveBoundaries) {
      return !_safeArea.contains(center);
    }
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

  LatLng containPoint(LatLng point, LatLng fallback) {
    if (adaptiveBoundaries) {
      return _safeArea.containPoint(point, fallback);
    } else {
      return LatLng(
        point.latitude.clamp(swPanBoundary.latitude, nePanBoundary.latitude),
        point.longitude.clamp(swPanBoundary.longitude, nePanBoundary.longitude),
      );
    }
  }

  _SafeArea get _safeArea {
    final controllerZoom = _getControllerZoom();
    if (controllerZoom != _safeAreaZoom || _safeAreaCache == null) {
      _safeAreaZoom = controllerZoom;
      final halfScreenHeight = _calculateScreenHeightInDegrees() / 2;
      final halfScreenWidth = _calculateScreenWidthInDegrees() / 2;
      final southWestLatitude = swPanBoundary.latitude + halfScreenHeight;
      final southWestLongitude = swPanBoundary.longitude + halfScreenWidth;
      final northEastLatitude = nePanBoundary.latitude - halfScreenHeight;
      final northEastLongitude = nePanBoundary.longitude - halfScreenWidth;
      _safeAreaCache = _SafeArea(
        LatLng(
          southWestLatitude,
          southWestLongitude,
        ),
        LatLng(
          northEastLatitude,
          northEastLongitude,
        ),
      );
    }
    return _safeAreaCache;
  }

  double _calculateScreenWidthInDegrees() {
    final zoom = _getControllerZoom();
    final degreesPerPixel = 360 / pow(2, zoom + 8);
    return screenSize.width * degreesPerPixel;
  }

  double _calculateScreenHeightInDegrees() =>
      screenSize.height * 170.102258 / pow(2, _getControllerZoom() + 8);

  double _getControllerZoom() => controller.ready ? controller.zoom : zoom;
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

class _SafeArea {
  final LatLngBounds bounds;
  final bool isLatitudeBlocked;
  final bool isLongitudeBlocked;

  _SafeArea(LatLng southWest, LatLng northEast)
      : bounds = LatLngBounds(southWest, northEast),
        isLatitudeBlocked = southWest.latitude > northEast.latitude,
        isLongitudeBlocked = southWest.longitude > northEast.longitude;

  bool contains(point) =>
      isLatitudeBlocked || isLongitudeBlocked ? false : bounds.contains(point);

  LatLng containPoint(LatLng point, LatLng fallback) => LatLng(
        isLatitudeBlocked
            ? fallback.latitude
            : point.latitude.clamp(bounds.south, bounds.north),
        isLongitudeBlocked
            ? fallback.longitude
            : point.longitude.clamp(bounds.west, bounds.east),
      );
}
