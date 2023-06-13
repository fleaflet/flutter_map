import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/map/flutter_map_internal_controller.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
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
      _internalController.move(
        center,
        zoom,
        offset: offset,
        hasGesture: false,
        source: MapEventSource.mapController,
        id: id,
      );

  @override
  bool rotate(double degree, {String? id}) => _internalController.rotate(
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
      _internalController.rotateAroundPoint(
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
      _internalController.moveAndRotate(
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
    FitBoundsOptions options = const FitBoundsOptions(
      padding: EdgeInsets.all(12),
    ),
  }) =>
      _internalController.fitBounds(bounds, options, offset: Offset.zero);

  @override
  CenterZoom centerZoomFitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions options = const FitBoundsOptions(
      padding: EdgeInsets.all(12),
    ),
  }) =>
      options.fit(mapState, bounds);

  @override
  FlutterMapState get mapState => _internalController.mapState;

  final _mapEventStreamController = StreamController<MapEvent>.broadcast();

  @override
  Stream<MapEvent> get mapEventStream => _mapEventStreamController.stream;

  StreamSink<MapEvent> get mapEventSink => _mapEventStreamController.sink;

  late FlutterMapInternalController _internalController;

  set internalController(FlutterMapInternalController internalController) {
    _internalController = internalController;
  }

  @override
  void dispose() {
    _mapEventStreamController.close();
  }
}
