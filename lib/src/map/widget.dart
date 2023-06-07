import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/flutter_map_state_container.dart';

/// Renders an interactive geographical map as a widget
///
/// See the online documentation for more information about set-up,
/// configuration, and usage.
class FlutterMap extends StatefulWidget {
  /// Renders an interactive geographical map as a widget
  ///
  /// See the online documentation for more information about set-up,
  /// configuration, and usage.
  const FlutterMap({
    super.key,
    required this.options,
    this.children = const [],
    this.nonRotatedChildren = const [],
    this.mapController,
  });

  /// Layers/widgets to be painted onto the map, in a [Stack]-like fashion
  final List<Widget> children;

  /// Same as [children], except these are unnaffected by map rotation
  final List<Widget> nonRotatedChildren;

  /// Configure this map
  final MapOptions options;

  /// Programatically interact with this map
  final MapController? mapController;

  @override
  State<FlutterMap> createState() => FlutterMapStateContainer();
}
