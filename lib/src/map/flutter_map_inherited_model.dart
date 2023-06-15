import 'package:flutter/material.dart';
import 'package:flutter_map/src/map/flutter_map_frame.dart';
import 'package:flutter_map/src/map/map_controller.dart';
import 'package:flutter_map/src/map/options.dart';

class FlutterMapInheritedModel extends InheritedModel<_FlutterMapAspect> {
  final FlutterMapData data;

  FlutterMapInheritedModel({
    super.key,
    required FlutterMapFrame frame,
    required MapController controller,
    required MapOptions options,
    required super.child,
  }) : data = FlutterMapData(
          frame: frame,
          controller: controller,
          options: options,
        );

  static FlutterMapData? _maybeOf(
    BuildContext context, [
    _FlutterMapAspect? aspect,
  ]) =>
      InheritedModel.inheritFrom<FlutterMapInheritedModel>(context,
              aspect: aspect)
          ?.data;

  static FlutterMapFrame? maybeFrameOf(BuildContext context) =>
      _maybeOf(context, _FlutterMapAspect.frame)?.frame;

  static MapController? maybeControllerOf(BuildContext context) =>
      _maybeOf(context, _FlutterMapAspect.controller)?.controller;

  static MapOptions? maybeOptionsOf(BuildContext context) =>
      _maybeOf(context, _FlutterMapAspect.options)?.options;

  @override
  bool updateShouldNotify(FlutterMapInheritedModel oldWidget) =>
      data != oldWidget.data;

  @override
  bool updateShouldNotifyDependent(
      covariant FlutterMapInheritedModel oldWidget, Set<Object> dependencies) {
    for (final dependency in dependencies) {
      if (dependency is _FlutterMapAspect) {
        switch (dependency) {
          case _FlutterMapAspect.frame:
            if (data.frame != oldWidget.data.frame) return true;
          case _FlutterMapAspect.controller:
            if (data.controller != oldWidget.data.controller) return true;
          case _FlutterMapAspect.options:
            if (data.options != oldWidget.data.options) return true;
        }
      }
    }

    return false;
  }
}

class FlutterMapData {
  final FlutterMapFrame frame;
  final MapController controller;
  final MapOptions options;

  const FlutterMapData({
    required this.frame,
    required this.controller,
    required this.options,
  });
}

enum _FlutterMapAspect {
  frame,
  controller,
  options;
}
