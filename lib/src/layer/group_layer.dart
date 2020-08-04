import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';

/// [LayerOptions] that describe a layer composed by multiple built-in layers.
class GroupLayerOptions extends LayerOptions {
  List<LayerOptions> group = <LayerOptions>[];

  GroupLayerOptions({
    Key key,
    this.group,
    rebuild,
  }) : super(key: key, rebuild: rebuild);
}

class GroupLayerWidget extends StatelessWidget {
  final GroupLayerOptions options;

  GroupLayerWidget({@required this.options}) : super(key: options.key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.of(context);
    return GroupLayer(options, mapState, mapState.onMoved);
  }
}

class GroupLayer extends StatelessWidget {
  final GroupLayerOptions groupOpts;
  final MapState map;
  final Stream<Null> stream;

  GroupLayer(this.groupOpts, this.map, this.stream) : super(key: groupOpts.key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      // TODO unused BoxContraints should remove?
      builder: (BuildContext context, BoxConstraints bc) {
        return _build(context);
      },
    );
  }

  Widget _build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (BuildContext context, _) {
        var layers = <Widget>[
          for (var options in groupOpts.group) _createLayer(options)
        ];

        return Container(
          child: Stack(
            children: layers,
          ),
        );
      },
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
