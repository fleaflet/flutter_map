library leaflet_flutter;

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/geo/crs/crs.dart';
import 'package:flutter_map/src/gestures/gestures.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';

export 'src/layer/layer.dart';
export 'src/layer/tile_layer.dart';
export 'src/layer/marker_layer.dart';
export 'src/layer/polyline_layer.dart';

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

  _FlutterMapState createState() => new _FlutterMapState();
}

abstract class MapController {
  /// Moves the map to a specific location and zoom level
  void move(LatLng center, double zoom);

  factory MapController() => new MapControllerImpl();
}

typedef TapCallback(LatLng point);

class MapOptions {
  final Crs crs;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final List<LayerOptions> layers;
  final bool debug;
  final bool interactive;
  final TapCallback onTap;
  LatLng center;

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
  }) {
    if (center == null) center = new LatLng(50.5, 30.51);
  }
}

class _FlutterMapState extends MapGestureMixin {
  MapOptions get options => widget.options ?? new MapOptions();
  MapState mapState;

  initState() {
    super.initState();
    mapState = new MapState(options);
    widget._mapController.state = mapState;
  }

  void didUpdateWidget(FlutterMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget._mapController != oldWidget._mapController) {
      widget._mapController.state = mapState;
    }
  }

  Widget build(BuildContext context) {
    return new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      mapState.size =
          new Point<double>(constraints.maxWidth, constraints.maxHeight);
      var layerWidgets = widget.layers.map(_createLayer).toList();
      return new GestureDetector(
        onScaleStart: handleScaleStart,
        onScaleUpdate: handleScaleUpdate,
        onScaleEnd: handleScaleEnd,
        onTapUp: handleTapUp,
        child: new Container(
          child: new Stack(
            children: layerWidgets,
          ),
        ),
      );
    });
  }

  Widget _createLayer(LayerOptions options) {
    if (options is TileLayerOptions) {
      return new TileLayer(options: options, mapState: mapState);
    }
    if (options is MarkerLayerOptions) {
      return new MarkerLayer(options, mapState);
    }
    if (options is PolylineLayerOptions) {
      return new PolylineLayer(options, mapState);
    }
    return null;
  }
}
