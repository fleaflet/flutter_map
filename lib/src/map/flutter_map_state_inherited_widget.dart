import 'package:flutter/material.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:flutter_map/src/map/map_controller.dart';
import 'package:flutter_map/src/map/options.dart';

class MapStateInheritedWidget extends InheritedWidget {
  const MapStateInheritedWidget({
    super.key,
    required this.state,
    required this.controller,
    required this.options,
    required super.child,
  });

  final FlutterMapState state;
  final MapController controller;
  final MapOptions options;

  @override
  bool updateShouldNotify(MapStateInheritedWidget oldWidget) =>
      !identical(state, oldWidget.state) ||
      !identical(controller, oldWidget.controller) ||
      !identical(options, oldWidget.options);
}
