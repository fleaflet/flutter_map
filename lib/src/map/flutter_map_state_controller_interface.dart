import 'package:flutter/rendering.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/misc/center_zoom.dart';
import 'package:flutter_map/src/misc/fit_bounds_options.dart';
import 'package:flutter_map/src/misc/move_and_rotate_result.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:latlong2/latlong.dart';

/// Defines the methods that the MapController may call on the
/// FlutterMapStateController. This clarifies the link between the two classes.
abstract interface class FlutterMapStateControllerInterface {
  LatLng get center;
  double get zoom;
  double get rotation;
  LatLngBounds? get bounds;

  bool move(
    LatLng newCenter,
    double newZoom, {
    required Offset offset,
    required bool hasGesture,
    required MapEventSource source,
    required String? id,
  });

  bool rotate(
    double newRotation, {
    required bool hasGesture,
    required MapEventSource source,
    required String? id,
  });

  MoveAndRotateResult rotateAroundPoint(
    double degree, {
    required CustomPoint<double>? point,
    required Offset? offset,
    required bool hasGesture,
    required MapEventSource source,
    required String? id,
  });

  MoveAndRotateResult moveAndRotate(
    LatLng newCenter,
    double newZoom,
    double newRotation, {
    required Offset offset,
    required bool hasGesture,
    required MapEventSource source,
    required String? id,
  });

  bool fitBounds(
    LatLngBounds bounds,
    FitBoundsOptions options, {
    required Offset offset,
  });

  CenterZoom centerZoomFitBounds(
    LatLngBounds bounds,
    FitBoundsOptions options,
  );

  LatLng pointToLatLng(CustomPoint localPoint);

  CustomPoint<double> latLngToScreenPoint(LatLng latLng);

  CustomPoint<double> rotatePoint(
    CustomPoint mapCenter,
    CustomPoint point, {
    required bool counterRotation,
  });
}
