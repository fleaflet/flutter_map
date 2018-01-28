library leaflet_flutter;

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:leaflet_flutter/leaflet_flutter.dart';
import 'package:leaflet_flutter/src/core/point.dart';
import 'package:leaflet_flutter/src/map/map.dart';

export 'src/layer/layer.dart';
export 'src/layer/tile_layer.dart';
export 'src/map/map.dart';

class Leaflet extends StatefulWidget {
  final List<LayerOptions> layers;
  final MapOptions options;
  Leaflet({this.options, this.layers});
  State<StatefulWidget> createState() {
    return new LeafletState();
  }
}

class LeafletState extends State<Leaflet> {
  MapOptions get options => widget.options;

  initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      var mapState = new MapState(options);
      mapState.size = new Point<double>(constraints.maxWidth, constraints.maxHeight);
      return new Container(
        child: new Stack(
          children: widget.layers
              .map(
                (opts) => new TileLayer(options: opts, mapState: mapState),
              )
              .toList(),
        ),
      );
    });
  }
}
