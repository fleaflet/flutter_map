import 'package:flutter/widgets.dart';

import '../../flutter_map.dart';
import '../core/point.dart';
import '../gestures/gestures.dart';
import '../map/map.dart';

class FlutterMapState extends MapGestureMixin {
  final MapControllerImpl mapController;
  MapOptions get options => widget.options ?? new MapOptions();
  MapState mapState;

  FlutterMapState(this.mapController);

  initState() {
    super.initState();
    mapState = new MapState(options);
    mapController.state = mapState;
  }

  Widget build(BuildContext context) {
    return new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      mapState.size =
          new Point<double>(constraints.maxWidth, constraints.maxHeight);
      var layerWidgets = widget.layers
          .map((layer) => _createLayer(layer, widget.options.plugins))
          .toList();
      return new GestureDetector(
        onScaleStart: handleScaleStart,
        onScaleUpdate: handleScaleUpdate,
        onScaleEnd: handleScaleEnd,
        onTapUp: handleTapUp,
        onDoubleTap: handleDoubleTap,
        child: new Container(
          child: new Stack(
            children: layerWidgets,
          ),
        ),
      );
    });
  }

  Widget _createLayer(LayerOptions options, List<MapPlugin> plugins) {
    if (options is TileLayerOptions) {
      return new TileLayer(options: options, mapState: mapState);
    }
    if (options is MarkerLayerOptions) {
      return new MarkerLayer(options, mapState);
    }
    if (options is PolylineLayerOptions) {
      return new PolylineLayer(options, mapState);
    }
    for (var plugin in plugins) {
      if (plugin.supportsLayer(options)) {
        return plugin.createLayer(options, mapState);
      }
    }
    return null;
  }
}
