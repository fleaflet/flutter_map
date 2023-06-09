import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/gestures/flutter_map_state_controller.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/map/flutter_map_state_controller_interface.dart';
import 'package:flutter_map/src/map/map_controller.dart';
import 'package:flutter_map/src/misc/center_zoom.dart';
import 'package:flutter_map/src/misc/fit_bounds_options.dart';
import 'package:flutter_map/src/misc/move_and_rotate_result.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:latlong2/latlong.dart';

class MapControllerImpl implements MapController {
  MapControllerImpl();

  @override
  bool move(
    LatLng center,
    double zoom, {
    Offset offset = Offset.zero,
    String? id,
  }) =>
      _stateController.move(
        center,
        zoom,
        offset: offset,
        hasGesture: false,
        source: MapEventSource.mapController,
        id: id,
      );

  @override
  bool rotate(double degree, {String? id}) => _stateController.rotate(
        degree,
        hasGesture: false,
        source: MapEventSource.mapController,
        id: id,
      );

  @override
  MoveAndRotateResult rotateAroundPoint(
    double degree, {
    CustomPoint<double>? point,
    Offset? offset,
    String? id,
  }) =>
      _stateController.rotateAroundPoint(
        degree,
        point: point,
        offset: offset,
        hasGesture: false,
        source: MapEventSource.mapController,
        id: id,
      );

  @override
  MoveAndRotateResult moveAndRotate(
    LatLng center,
    double zoom,
    double degree, {
    String? id,
  }) =>
      _stateController.moveAndRotate(
        center,
        zoom,
        degree,
        offset: Offset.zero,
        hasGesture: false,
        source: MapEventSource.mapController,
        id: id,
      );

  @override
  bool fitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions? options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  }) =>
      _stateController.fitBounds(
        bounds,
        options!,
        offset: Offset.zero,
      );

  @override
  CenterZoom centerZoomFitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions? options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  }) =>
      _stateController.centerZoomFitBounds(bounds, options!);

  @override
  LatLng pointToLatLng(CustomPoint localPoint) =>
      _stateController.pointToLatLng(localPoint);

  @override
  CustomPoint<double> latLngToScreenPoint(LatLng latLng) =>
      _stateController.latLngToScreenPoint(latLng);

  @override
  CustomPoint<double> rotatePoint(
    CustomPoint mapCenter,
    CustomPoint point, {
    bool counterRotation = true,
  }) =>
      _stateController.rotatePoint(
        mapCenter.toDoublePoint(),
        point.toDoublePoint(),
        counterRotation: counterRotation,
      );

  @override
  LatLng get center => _stateController.center;

  @override
  LatLngBounds? get bounds => _stateController.bounds;

  @override
  double get zoom => _stateController.zoom;

  @override
  double get rotation => _stateController.rotation;

  final _mapEventStreamController = StreamController<MapEvent>.broadcast();

  @override
  Stream<MapEvent> get mapEventStream => _mapEventStreamController.stream;

  StreamSink<MapEvent> get mapEventSink => _mapEventStreamController.sink;

  late FlutterMapStateControllerInterface _stateController;

  set stateController(FlutterMapStateController stateController) {
    _stateController = stateController;
  }

  @override
  void dispose() {
    _mapEventStreamController.close();
  }
}
