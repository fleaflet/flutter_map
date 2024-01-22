import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Allows descendents of [FlutterMap] to access the [MapCamera], [MapOptions]
/// and [MapController]. Those classes provide of/maybeOf methods for users to
/// use, those methods call the relevant methods provided by this class.
///
/// Using an [InheritedModel] means dependent widgets will only rebuild when
/// the aspect they reference is updated.
@immutable
class MapInheritedModel extends InheritedModel<_FlutterMapAspect> {
  /// The current [FlutterMapData].
  /// Access the state by calling e.g. `MapController.of(context)`.
  final FlutterMapData data;

  /// Create a new [MapInheritedModel] instance.
  MapInheritedModel({
    super.key,
    required MapCamera camera,
    required MapController controller,
    required MapOptions options,
    required super.child,
  }) : data = FlutterMapData(
          camera: camera,
          controller: controller,
          options: options,
        );

  static FlutterMapData? _maybeOf(
    BuildContext context, [
    _FlutterMapAspect? aspect,
  ]) =>
      InheritedModel.inheritFrom<MapInheritedModel>(context, aspect: aspect)
          ?.data;

  /// Try to get the [MapCamera] instance for the given [FlutterMap] context.
  static MapCamera? maybeCameraOf(BuildContext context) =>
      _maybeOf(context, _FlutterMapAspect.camera)?.camera;

  /// Try to get the [MapController] instance for the given
  /// [FlutterMap] context.
  static MapController? maybeControllerOf(BuildContext context) =>
      _maybeOf(context, _FlutterMapAspect.controller)?.controller;

  /// Try to get the [MapOptions] for the given [FlutterMap] context.
  static MapOptions? maybeOptionsOf(BuildContext context) =>
      _maybeOf(context, _FlutterMapAspect.options)?.options;

  @override
  bool updateShouldNotify(MapInheritedModel oldWidget) =>
      data != oldWidget.data;

  @override
  bool updateShouldNotifyDependent(
    covariant MapInheritedModel oldWidget,
    Set<Object> dependencies,
  ) {
    for (final dependency in dependencies) {
      if (dependency is _FlutterMapAspect) {
        switch (dependency) {
          case _FlutterMapAspect.camera:
            if (data.camera != oldWidget.data.camera) return true;
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

/// The state data for the [MapInheritedModel]
@immutable
class FlutterMapData {
  /// The [MapCamera] that gets returned when calling `MapCamera.of(context)`.
  final MapCamera camera;

  /// The [MapController] that gets returned when calling `MapController.of(context)`.
  final MapController controller;

  /// The [MapOptions] that gets returned when calling `MapOptions.of(context)`.
  final MapOptions options;

  /// Create a new [FlutterMapData] instance by supplying all parameters.
  const FlutterMapData({
    required this.camera,
    required this.controller,
    required this.options,
  });
}

enum _FlutterMapAspect { camera, controller, options }
