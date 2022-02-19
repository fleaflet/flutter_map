import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';

class GroupLayerPlugin extends MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    return GroupLayer(options as GroupLayerOptions, mapState, stream);
  }

  @override
  bool supportsLayer(LayerOptions options) => options is GroupLayerOptions;
}

/// [LayerOptions] that describe a layer composed by multiple built-in layers.
class GroupLayerOptions extends LayerOptions {
  List<LayerOptions> group = <LayerOptions>[];

  GroupLayerOptions({
    Key? key,
    this.group = const [],
    Stream<Null>? rebuild,
  }) : super(key: key, rebuild: rebuild);
}

class GroupLayerWidget extends StatelessWidget {
  final GroupLayerOptions options;

  GroupLayerWidget({Key? key, required this.options}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return GroupLayer(options, mapState, mapState.onMoved);
  }
}

class GroupLayer extends StatelessWidget {
  final GroupLayerOptions groupOpts;
  final MapState mapState;
  final Stream<Null> stream;

  GroupLayer(this.groupOpts, this.mapState, this.stream)
      : super(key: groupOpts.key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (BuildContext context, _) {
        var layers = <Widget>[
          for (var options in groupOpts.group)
            _createLayer(options, mapState.options.plugins)
        ];

        return Container(
          child: Stack(
            children: layers,
          ),
        );
      },
    );
  }

  Widget _createLayer(LayerOptions options, List<MapPlugin> plugins) {
    final stream = options.rebuild ?? Stream.empty();

    for (var plugin in plugins) {
      if (plugin.supportsLayer(options)) {
        return plugin.createLayer(options, mapState, stream);
      }
    }
    throw Exception('Unknown options type for GeometryLayer: $options');
  }
}
