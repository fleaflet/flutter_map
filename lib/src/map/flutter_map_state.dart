import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/gestures/gestures.dart';
import 'package:flutter_map/src/layer/group_layer.dart';
import 'package:flutter_map/src/layer/overlay_image_layer.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';
import 'package:async/async.dart';

class FlutterMapState extends MapGestureMixin {
  final MapControllerImpl mapController;
  final List<StreamGroup<Null>> groups = <StreamGroup<Null>>[];

  @override
  MapOptions get options => widget.options ?? MapOptions();

  @override
  MapState mapState;

  FlutterMapState(this.mapController);

  @override
  void initState() {
    super.initState();
    mapState = MapState(options);
    mapController.state = mapState;
  }

  void _dispose() {
    for (var group in groups) {
      group.close();
    }

    groups.clear();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Stream<Null> _merge(LayerOptions options) {
    if (options?.rebuild == null) return mapState.onMoved;

    var group = StreamGroup<Null>();
    group.add(mapState.onMoved);
    group.add(options.rebuild);
    groups.add(group);
    return group.stream;
  }

  @override
  Widget build(BuildContext context) {
    _dispose();
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      mapState.size =
          CustomPoint<double>(constraints.maxWidth, constraints.maxHeight);
      var layerWidgets = widget.layers
          .map((layer) => _createLayer(layer, widget.options.plugins))
          .toList();

      var layerWidgetsContainer = Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: Stack(
          children: layerWidgets,
        ),
      );

      if (!options.interactive) {
        return layerWidgetsContainer;
      }

      return PositionedTapDetector(
        onTap: handleTap,
        onLongPress: handleLongPress,
        onDoubleTap: handleDoubleTap,
        child: GestureDetector(
          onScaleStart: handleScaleStart,
          onScaleUpdate: handleScaleUpdate,
          onScaleEnd: handleScaleEnd,
          child: layerWidgetsContainer,
        ),
      );
    });
  }

  Widget _createLayer(LayerOptions options, List<MapPlugin> plugins) {
    if (options is TileLayerOptions) {
      return TileLayer(
          options: options, mapState: mapState, stream: _merge(options));
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
      return CircleLayer(options, mapState, _merge(options));
    }
    if (options is GroupLayerOptions) {
      return GroupLayer(options, mapState, _merge(options));
    }
    if (options is OverlayImageLayerOptions) {
      return OverlayImageLayer(options, mapState, _merge(options));
    }
    for (var plugin in plugins) {
      if (plugin.supportsLayer(options)) {
        return plugin.createLayer(options, mapState, _merge(options));
      }
    }
    return null;
  }
}
