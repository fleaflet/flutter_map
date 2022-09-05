import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:latlong2/latlong.dart';

class MapControllerImpl implements MapController {
  final StreamController<MapEvent> _mapEventSink = StreamController.broadcast();

  @override
  StreamSink<MapEvent> get mapEventSink => _mapEventSink.sink;

  @override
  Stream<MapEvent> get mapEventStream => _mapEventSink.stream;

  late FlutterMapState _state;

  @override
  set state(FlutterMapState state) {
    _state = state;
  }

  @override
  void dispose() {
    _mapEventSink.close();
  }

  @override
  MoveAndRotateResult moveAndRotate(LatLng center, double zoom, double degree,
      {String? id}) {
    return _state.moveAndRotate(center, zoom, degree,
        source: MapEventSource.mapController, id: id);
  }

  @override
  bool move(LatLng center, double zoom, {String? id}) {
    return _state.move(center, zoom,
        id: id, source: MapEventSource.mapController);
  }

  @override
  void fitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions? options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  }) {
    _state.fitBounds(bounds, options!);
  }

  @override
  CenterZoom centerZoomFitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions? options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  }) {
    return _state.centerZoomFitBounds(bounds, options!);
  }

  @override
  LatLng get center => _state.center;

  @override
  LatLngBounds? get bounds => _state.bounds;

  @override
  double get zoom => _state.zoom;

  @override
  double get rotation => _state.rotation;

  @override
  bool rotate(double degree, {String? id}) {
    return _state.rotate(degree, id: id, source: MapEventSource.mapController);
  }

  @override
  CustomPoint latLngToScreenPoint(LatLng latLng) {
    return _state.latLngToScreenPoint(latLng);
  }

  @override
  LatLng? pointToLatLng(CustomPoint localPoint) {
    return _state.pointToLatLng(localPoint);
  }

  CustomPoint<num> rotatePoint(
      CustomPoint<num> mapCenter, CustomPoint<num> point,
      {bool counterRotation = true}) {
    return _state.rotatePoint(mapCenter, point,
        counterRotation: counterRotation);
  }
}
