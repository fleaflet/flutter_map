import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/gestures/gestures.dart';
import 'package:flutter_map/src/map/map.dart';

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
