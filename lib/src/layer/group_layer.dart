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

  Widget build(BuildContext context) {
    return new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        return _build(context);
      },
    );
  }

  Widget _build(BuildContext context) {
    var layers = <Widget>[];

    groupOpts.group.forEach((options) =>
        layers.add(_createLayer(options)));

    return new Container(
      child: new Stack(
        children: layers,
      ),
    );

  }

  Widget _createLayer(LayerOptions options) {
    if (options is MarkerLayerOptions) {
      return new MarkerLayer(
          options, map, options.rebuild);
    }
    if (options is CircleLayerOptions) {
      return new CircleLayer(
          options, map, options.rebuild);
    }
    if (options is PolylineLayerOptions) {
      return new PolylineLayer(
          options, map, options.rebuild);
    }
    if (options is PolygonLayerOptions) {
      return new PolygonLayer(
          options, map, options.rebuild);
    }
    throw ("Unknown options type for GeometryLayer: $options");
  }
}