import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/gestures/gestures.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:async/async.dart';

class FlutterMapState extends MapGestureMixin {
  final MapControllerImpl mapController;
  final List<StreamGroup<Null>> groups = <StreamGroup<Null>>[];
  MapOptions get options => widget.options ?? MapOptions();
  MapState mapState;

  FlutterMapState(this.mapController);

  initState() {
    super.initState();
    mapState = MapState(options);
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
    StreamGroup<Null> group = StreamGroup<Null>();
    group.add(mapState.onMoved);
    group.add(options.rebuild);
    groups.add(group);
    return group.stream;
  }

  Widget build(BuildContext context) {
    _dispose();
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      mapState.size =
          Point<double>(constraints.maxWidth, constraints.maxHeight);
      var layerWidgets = widget.layers
          .map((layer) => _createLayer(layer, widget.options.plugins))
          .toList();
      return GestureDetector(
        onScaleStart: handleScaleStart,
        onScaleUpdate: handleScaleUpdate,
        onScaleEnd: handleScaleEnd,
        onTapUp: handleTapUp,
        onDoubleTap: handleDoubleTap,
        onTap: handleTap,
        onLongPress: handleLongPress,
        child: Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: layerWidgets,
          ),
        ),
      );
    });
  }

  Widget _createLayer(LayerOptions options, List<MapPlugin> plugins) {
    if (options is TileLayerOptions) {
      return TileLayer(options: options, mapState: mapState, stream: _merge(options));
    }
    if (options is MarkerLayerOptions) {
      return MarkerLayer(options, mapState, _merge(options));
    }
    if (options is PolylineLayerOptions) {
      return PolylineLayer(options, mapState, _merge(options));
    }
    if (options is PolygonLayerOptions) {
      return PolygonLayer(options, mapState, _merge(options));
    }
    if (options is CircleLayerOptions) {
      return CircleLayer(options, mapState);
    }
    for (var plugin in plugins) {
      if (plugin.supportsLayer(options)) {
        return plugin.createLayer(options, mapState, _merge(options));
      }
    }
    return null;
  }
}
