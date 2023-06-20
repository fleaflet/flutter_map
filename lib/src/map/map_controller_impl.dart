import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/map/camera.dart';
import 'package:flutter_map/src/map/flutter_map_internal_controller.dart';
import 'package:flutter_map/src/map/map_controller.dart';
import 'package:flutter_map/src/misc/camera_fit.dart';
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

  /// Move and zoom the map to perfectly fit [bounds], with additional
  /// configurable [options]
  ///
  /// For information about return value meaning and emitted events, see [move]'s
  /// documentation.
  @override
  @Deprecated('Use fitCamera with a MapFit.bounds() instead')
  bool fitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  }) =>
      fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: options.padding,
          maxZoom: options.maxZoom,
          inside: options.inside,
          forceIntegerZoomLevel: options.forceIntegerZoomLevel,
        ),
      );

  @override
  bool fitCamera(CameraFit cameraFit) => _internalController.fitCamera(
        cameraFit,
        offset: Offset.zero,
      );

  @override
  MapCamera get mapCamera => _internalController.mapCamera;

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

  @override
  @Deprecated('Use controller.mapCamera.visibleBounds instead.')
  LatLngBounds? get bounds => mapCamera.visibleBounds;

  @override
  @Deprecated('Use controller.mapCamera.center instead.')
  LatLng get center => mapCamera.center;

  @override
  @Deprecated(
      'Use CameraFit.bounds(bounds: bounds).fit(controller.mapCamera) instead.')
  CenterZoom centerZoomFitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  }) {
    final fittedState = CameraFit.bounds(
      bounds: bounds,
      padding: options.padding,
      maxZoom: options.maxZoom,
      inside: options.inside,
      forceIntegerZoomLevel: options.forceIntegerZoomLevel,
    ).fit(mapCamera);
    return CenterZoom(
      center: fittedState.center,
      zoom: fittedState.zoom,
    );
  }

  @override
  @Deprecated('Use controller.mapCamera.latLngToScreenPoint() instead.')
  CustomPoint<double> latLngToScreenPoint(LatLng mapCoordinate) =>
      mapCamera.latLngToScreenPoint(mapCoordinate);

  @override
  @Deprecated('Use controller.mapCamera.pointToLatLng() instead.')
  LatLng pointToLatLng(CustomPoint<num> screenPoint) =>
      mapCamera.pointToLatLng(screenPoint);

  @override
  @Deprecated('Use controller.mapCamera.rotatePoint() instead.')
  CustomPoint<double> rotatePoint(
    CustomPoint mapCenter,
    CustomPoint point, {
    bool counterRotation = true,
  }) =>
      mapCamera.rotatePoint(
        mapCenter.toDoublePoint(),
        point.toDoublePoint(),
        counterRotation: counterRotation,
      );

  @override
  @Deprecated('Use controller.mapCamera.rotation instead.')
  double get rotation => mapCamera.rotation;

  @override
  @Deprecated('Use controller.mapCamera.zoom instead.')
  double get zoom => mapCamera.zoom;
}
