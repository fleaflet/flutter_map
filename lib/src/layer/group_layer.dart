import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';

class GroupLayerOptions extends LayerOptions {
  List<LayerOptions> group = <LayerOptions>[];

  GroupLayerOptions({this.group});
}

class GroupLayer extends StatelessWidget {
  final GroupLayerOptions groupOpts;
  final MapState map;
  final Stream<Null> stream;

  GroupLayer(this.groupOpts, this.map, this.stream);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        return _build(context);
      },
    );
  }

  Widget _build(BuildContext context) {
    var layers = <Widget>[];

    for (var options in groupOpts.group) {
      layers.add(_createLayer(options));
    }

    return Container(
      child: Stack(
        children: layers,
      ),
    );
  }

  Widget _createLayer(LayerOptions options) {
    if (options is MarkerLayerOptions) {
      return MarkerLayer(options, map, options.rebuild);
    }
    if (options is CircleLayerOptions) {
      return CircleLayer(options, map, options.rebuild);
    }
    if (options is PolylineLayerOptions) {
      return PolylineLayer(options, map, options.rebuild);
    }
    if (options is PolygonLayerOptions) {
      return PolygonLayer(options, map, options.rebuild);
    }
    if (options is OverlayImageLayerOptions) {
      return OverlayImageLayer(options, map, options.rebuild);
    }
    throw Exception('Unknown options type for GeometryLayer: $options');
  }
}
