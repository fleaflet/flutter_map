import 'package:flutter/material.dart';
import 'package:flutter_map/src/map/controller.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';

class MapStateInheritedWidget extends InheritedWidget {
  const MapStateInheritedWidget({
    super.key,
    required this.mapState,
    required this.mapController,
    required super.child,
  });

  final FlutterMapState mapState;
  final MapController mapController;

  @override
  bool updateShouldNotify(MapStateInheritedWidget oldWidget) =>
      !identical(mapState, oldWidget.mapState) ||
      !identical(mapController, oldWidget.mapController);
}
