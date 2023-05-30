import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/state.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Controller to programmatically interact with [FlutterMap], such as
/// controlling it and accessing some of its properties.
///
/// See https://docs.fleaflet.dev/usage/controller#initialisation for information
/// on how to set-up and connect a controller to a map widget instance.
abstract class MapController {
  /// Controller to programmatically interact with [FlutterMap], such as
  /// controlling it and accessing some of its properties.
  ///
  /// See https://docs.fleaflet.dev/usage/controller#initialisation for
  /// information how to set-up and connect a controller to a map widget
  /// instance.
  ///
  /// Factory constructor redirects to underlying implementation's constructor.
  factory MapController() = MapControllerImpl._;

  /// Moves and zooms the map to a [center] and [zoom] level
  ///
  /// [offset] allows a screen-based offset (in normal logical pixels) to be
  /// applied to the [center] from the map's view center. For example,
  /// `Offset(100, 100)` will move the intended new [center] 100px down & 100px
  /// right, and the actual center will become 100px up & 100px left.
  ///
  /// [id] is an internally meaningless attribute, but it is passed through to
  /// the emitted [MapEventMove].
  ///
  /// The emitted [MapEventMove.source] property will be
  /// [MapEventSource.mapController].
  ///
  /// Returns `true` and emits a [MapEventMove] event (which can be listed to
  /// through [MapEventCallback]s, such as [MapOptions.onMapEvent]), unless
  /// the move failed because (after adjustment when necessary):
  ///  * [center] and [zoom] are equal to the current values
  ///  * [center] is out of bounds & [MapOptions.slideOnBoundaries] isn't enabled
  bool move(
    LatLng center,
    double zoom, {
    Offset offset = Offset.zero,
    String? id,
  });

  /// Rotates the map to a decimal [degree] around the current center, where 0°
  /// is North
  ///
  /// See [rotateAroundPoint] to rotate the map around a custom screen point.
  ///
  /// [id] is an internally meaningless attribute, but it is passed through to
  /// the emitted [MapEventRotate].
  ///
  /// The emitted [MapEventRotate.source] property will be
  /// [MapEventSource.mapController].
  ///
  /// Returns `true` and emits a [MapEventRotate] event (which can be listed to
  /// through [MapEventCallback]s, such as [MapOptions.onMapEvent]), unless
  /// the move failed because [degree] (after adjustment when necessary) was
  /// equal to the current value.
  bool rotate(double degree, {String? id});

  /// Rotates the map to a decimal [degree] around a custom screen point, where
  /// 0° is North
  ///
  /// See [rotate] to rotate the map around the current map center.
  ///
  /// One, and only one, of [point] or [offset] must be defined:
  ///  * [point]: allows rotation around a screen-based point (in normal logical
  /// pixels), where `Offset(0,0)` is the top-left of the map widget, and the
  /// bottom right is `Offset(mapWidth, mapHeight)`.
  ///  * [offset]: allows rotation around a screen-based offset (in normal logical
  /// pixels) from the map's [center]. For example, `Offset(100, 100)` will mean
  /// the point is the 100px down & 100px right from the [center].
  ///
  /// May cause glitchy movement if rotated against the map's bounds.
  ///
  /// [id] is an internally meaningless attribute, but it is passed through to
  /// the emitted [MapEventRotate] and [MapEventMove].
  ///
  /// The emitted [MapEventRotate.source]/[MapEventMove.source] properties will
  /// be [MapEventSource.mapController].
  ///
  /// The operation was successful if [MoveAndRotateResult.moveSuccess] and
  /// [MoveAndRotateResult.rotateSuccess] are `true`.
  MoveAndRotateResult rotateAroundPoint(
    double degree, {
    CustomPoint<double>? point,
    Offset? offset,
    String? id,
  });

  /// Calls [move] and [rotate] together, but is more efficient for the combined
  /// operation
  ///
  /// Does not support offsets or rotations around custom points.
  ///
  /// See documentation on those methods for more details.
  ///
  /// The operation was successful if [MoveAndRotateResult.moveSuccess] and
  /// [MoveAndRotateResult.rotateSuccess] are `true`.
  MoveAndRotateResult moveAndRotate(
    LatLng center,
    double zoom,
    double degree, {
    String? id,
  });

  /// Move and zoom the map to perfectly fit [bounds], with additional
  /// configurable [options]
  ///
  /// For information about return value meaning and emitted events, see [move]'s
  /// documentation.
  bool fitBounds(LatLngBounds bounds, {FitBoundsOptions? options});

  /// Calculates the appropriate center and zoom level for the map to perfectly
  /// fit [bounds], with additional configurable [options]
  ///
  /// Does not move/zoom the map: see [fitBounds].
  CenterZoom centerZoomFitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions? options,
  });

  /// Convert a screen point (x/y) to its corresponding map coordinate (lat/lng),
  /// based on the map's current properties
  LatLng pointToLatLng(CustomPoint screenPoint);

  /// Convert a map coordinate (lat/lng) to its corresponding screen point (x/y),
  /// based on the map's current screen positioning
  CustomPoint<double> latLngToScreenPoint(LatLng mapCoordinate);

  CustomPoint<double> rotatePoint(
    CustomPoint mapCenter,
    CustomPoint point, {
    bool counterRotation = true,
  });

  /// Current center coordinates
  LatLng get center;

  /// Current outer points/boundaries coordinates
  LatLngBounds? get bounds;

  /// Current zoom level
  double get zoom;

  /// Current rotation in degrees, where 0° is North
  double get rotation;

  /// [Stream] of all emitted [MapEvent]s
  Stream<MapEvent> get mapEventStream;

  /// Underlying [StreamSink] of [mapEventStream]
  ///
  /// Usually prefer to use [mapEventStream].
  StreamSink<MapEvent> get mapEventSink;

  /// Immediately change the internal map state
  ///
  /// Not recommended for external usage.
  set state(FlutterMapState state);

  /// Dispose of this controller by closing the [mapEventStream]'s
  /// [StreamController]
  ///
  /// Not recommended for external usage.
  void dispose();
}

@internal
class MapControllerImpl implements MapController {
  MapControllerImpl._();

  @override
  bool move(
    LatLng center,
    double zoom, {
    Offset offset = Offset.zero,
    String? id,
  }) =>
      _state.move(
        center,
        zoom,
        offset: offset,
        id: id,
        source: MapEventSource.mapController,
      );

  @override
  bool rotate(double degree, {String? id}) =>
      _state.rotate(degree, id: id, source: MapEventSource.mapController);

  @override
  MoveAndRotateResult rotateAroundPoint(
    double degree, {
    CustomPoint<double>? point,
    Offset? offset,
    String? id,
  }) =>
      _state.rotateAroundPoint(
        degree,
        point: point,
        offset: offset,
        id: id,
        source: MapEventSource.mapController,
      );

  @override
  MoveAndRotateResult moveAndRotate(
    LatLng center,
    double zoom,
    double degree, {
    String? id,
  }) =>
      _state.moveAndRotate(
        center,
        zoom,
        degree,
        source: MapEventSource.mapController,
        id: id,
      );

  @override
  bool fitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions? options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  }) =>
      _state.fitBounds(bounds, options!);

  @override
  CenterZoom centerZoomFitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions? options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  }) =>
      _state.centerZoomFitBounds(bounds, options!);

  @override
  LatLng pointToLatLng(CustomPoint localPoint) =>
      _state.pointToLatLng(localPoint);

  @override
  CustomPoint<double> latLngToScreenPoint(LatLng latLng) =>
      _state.latLngToScreenPoint(latLng);

  @override
  CustomPoint<double> rotatePoint(
    CustomPoint mapCenter,
    CustomPoint point, {
    bool counterRotation = true,
  }) =>
      _state.rotatePoint(
        mapCenter.toDoublePoint(),
        point.toDoublePoint(),
        counterRotation: counterRotation,
      );

  @override
  LatLng get center => _state.center;

  @override
  LatLngBounds? get bounds => _state.bounds;

  @override
  double get zoom => _state.zoom;

  @override
  double get rotation => _state.rotation;

  final _mapEventStreamController = StreamController<MapEvent>.broadcast();

  @override
  Stream<MapEvent> get mapEventStream => _mapEventStreamController.stream;

  @override
  StreamSink<MapEvent> get mapEventSink => _mapEventStreamController.sink;

  late FlutterMapState _state;

  @override
  set state(FlutterMapState state) {
    _state = state;
  }

  @override
  void dispose() {
    _mapEventStreamController.close();
  }
}
