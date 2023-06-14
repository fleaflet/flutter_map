import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/map/flutter_map_internal_controller.dart';
import 'package:flutter_map/src/map/flutter_map_state.dart';
import 'package:flutter_map/src/map/map_controller.dart';
import 'package:flutter_map/src/misc/center_zoom.dart';
import 'package:flutter_map/src/misc/fit_bounds_options.dart';
import 'package:flutter_map/src/misc/frame_fit.dart';
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
  @Deprecated('Use fitFrame with a MapFit.bounds() instead')
  bool fitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  }) =>
      fitFrame(
        FrameFit.bounds(
          bounds: bounds,
          padding: options.padding,
          maxZoom: options.maxZoom,
          inside: options.inside,
          forceIntegerZoomLevel: options.forceIntegerZoomLevel,
        ),
      );

  @override
  bool fitFrame(FrameFit frameFit) => _internalController.fitFrame(
        frameFit,
        offset: Offset.zero,
      );

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

  @override
  @Deprecated('Use controller.mapState.visibleBounds instead.')
  LatLngBounds? get bounds => mapState.visibleBounds;

  @override
  @Deprecated('Use controller.mapState.center instead.')
  LatLng get center => mapState.center;

  @override
  @Deprecated(
      'Use FrameFit.bounds(bounds: bounds).fit(controller.mapState) instead.')
  CenterZoom centerZoomFitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  }) {
    final fittedState = FrameFit.bounds(
      bounds: bounds,
      padding: options.padding,
      maxZoom: options.maxZoom,
      inside: options.inside,
      forceIntegerZoomLevel: options.forceIntegerZoomLevel,
    ).fit(mapState);
    return CenterZoom(
      center: fittedState.center,
      zoom: fittedState.zoom,
    );
  }

  @override
  @Deprecated('Use controller.mapState.latLngToScreenPoint() instead.')
  CustomPoint<double> latLngToScreenPoint(LatLng mapCoordinate) =>
      mapState.latLngToScreenPoint(mapCoordinate);

  @override
  @Deprecated('Use controller.mapState.pointToLatLng() instead.')
  LatLng pointToLatLng(CustomPoint<num> screenPoint) =>
      mapState.pointToLatLng(screenPoint);

  @override
  @Deprecated('Use controller.mapState.rotatePoint() instead.')
  CustomPoint<double> rotatePoint(
    CustomPoint mapCenter,
    CustomPoint point, {
    bool counterRotation = true,
  }) =>
      mapState.rotatePoint(
        mapCenter.toDoublePoint(),
        point.toDoublePoint(),
        counterRotation: counterRotation,
      );

  @override
  @Deprecated('Use controller.mapState.rotation instead.')
  double get rotation => mapState.rotation;

  @override
  @Deprecated('Use controller.mapState.zoom instead.')
  double get zoom => mapState.zoom;
}
