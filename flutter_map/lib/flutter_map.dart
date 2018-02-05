library leaflet_flutter;

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/map/map.dart';

export 'src/layer/layer.dart';
export 'src/layer/tile_layer.dart';
export 'src/layer/marker_layer.dart';
export 'src/map/map.dart';

class FlutterMap extends StatefulWidget {
  final List<LayerOptions> layers;
  final MapOptions options;
  FlutterMap({this.options, this.layers});
  State<StatefulWidget> createState() {
    return new _FlutterMapState();
  }
}

class _FlutterMapState extends State<FlutterMap> {
  MapOptions get options => widget.options;
  MapState mapState;

  initState() {
    super.initState();
    mapState = new MapState(options);
  }

  Widget build(BuildContext context) {
    return new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      mapState.size =
          new Point<double>(constraints.maxWidth, constraints.maxHeight);
      return new Container(
        child: new Stack(
          children: widget.layers.map(_createLayer).toList(),
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
    return null;
  }
}
