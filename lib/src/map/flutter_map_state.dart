import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/gestures/gestures.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:async/async.dart';

class FlutterMapState extends MapGestureMixin {
  final MapControllerImpl mapController;
  final List<StreamGroup<Null>> groups = <StreamGroup<Null>>[];
  MapOptions get options => widget.options ?? new MapOptions();
  MapState mapState;

  FlutterMapState(this.mapController);

  initState() {
    super.initState();
    mapState = new MapState(options);
    mapController.state = mapState;
  }

  void _dispose() {
    groups.forEach((group) => group.close());
    groups.clear();
  }


  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Stream<Null> _merge(LayerOptions options) {
    if(options?.rebuild == null)
      return mapState.onMoved;

    StreamGroup<Null> group = new StreamGroup<Null>();
    group.add(mapState.onMoved);
    group.add(options.rebuild);
    groups.add(group);
    return group.stream;
  }

  Widget build(BuildContext context) {
    _dispose();
    return new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      mapState.size =
          new Point<double>(constraints.maxWidth, constraints.maxHeight);
      var layerWidgets = widget.layers
          .map((layer) => _createLayer(layer, widget.options.plugins))
          .toList();
      return new GestureDetector(
        onScaleStart: options.interactive ? handleScaleStart : null,
        onScaleUpdate: options.interactive ? handleScaleUpdate : null,
        onScaleEnd: options.interactive ? handleScaleEnd : null,
        onTapUp: handleTapUp,
        onDoubleTap: options.interactive ? handleDoubleTap : null,
        child: new Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: new Stack(
            children: layerWidgets,
          ),
        ),
      );
    });
  }

  Widget _createLayer(LayerOptions options, List<MapPlugin> plugins) {
    if (options is TileLayerOptions) {
      return new TileLayer(options: options, mapState: mapState, stream: _merge(options));
    }
    if (options is MarkerLayerOptions) {
      return new MarkerLayer(options, mapState, _merge(options));
    }
    if (options is PolylineLayerOptions) {
      return new PolylineLayer(options, mapState, _merge(options));
    }
    if (options is PolygonLayerOptions) {
      return new PolygonLayer(options, mapState, _merge(options));
    }
    if (options is CircleLayerOptions) {
      return new CircleLayer(options, mapState);
    }
    for (var plugin in plugins) {
      if (plugin.supportsLayer(options)) {
        return plugin.createLayer(options, mapState, _merge(options));
      }
    }
    return null;
  }
}
