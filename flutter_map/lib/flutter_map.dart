library leaflet_flutter;

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/gestures/gestures.dart';
import 'package:flutter_map/src/map/map.dart';

export 'src/layer/layer.dart';
export 'src/layer/tile_layer.dart';
export 'src/layer/marker_layer.dart';
export 'src/layer/polyline_layer.dart';
export 'src/map/map.dart';

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

  /// A [MapState], used to control the map
  final MapState mapState;

  FlutterMap({
    Key key,
    this.options,
    this.layers,
    this.mapState,
  })
      : super(key: key);

  _FlutterMapState createState() => new _FlutterMapState();
}

class _FlutterMapState extends MapGestureMixin {
  MapOptions get options => widget.options;
  MapState mapState;

  initState() {
    super.initState();
    mapState = widget.mapState ?? new MapState(options);
  }

  void didUpdateWidget(FlutterMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mapState != oldWidget.mapState) {
      final MapState newMapState = widget.mapState ?? new MapState(options);
      if (newMapState == mapState) return;
      if (mapState != null) mapState.dispose();
      mapState = newMapState;
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
