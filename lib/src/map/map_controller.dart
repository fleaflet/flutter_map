import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:flutter_map/src/map/camera/camera_fit.dart';
import 'package:flutter_map/src/map/inherited_model.dart';
import 'package:flutter_map/src/map/map_controller_impl.dart';
import 'package:flutter_map/src/misc/center_zoom.dart';
import 'package:flutter_map/src/misc/fit_bounds_options.dart';
import 'package:latlong2/latlong.dart';

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
  factory MapController() = MapControllerImpl;

  /// The controller for the closest [FlutterMap] ancestor. If this is called
  /// from a context with no [FlutterMap] ancestor a [StateError] will be
  /// thrown.
  static MapController? maybeOf(BuildContext context) =>
      FlutterMapInheritedModel.maybeControllerOf(context);

  /// The controller for the closest [FlutterMap] ancestor. If this is called
  /// from a context with no [FlutterMap] ancestor a [StateError] will be
  /// thrown.
  static MapController of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError(
          '`MapController.of()` should not be called outside a `FlutterMap` and its children'));

  /// [Stream] of all emitted [MapEvent]s
  Stream<MapEvent> get mapEventStream;

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
  ///  * [center] [MapOptions.cameraConstraint] does not allow the movement.
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
  /// pixels) from the map's center. For example, `Offset(100, 100)` will mean
  /// the point is the 100px down & 100px right from the center.
  ///
  /// May cause glitchy movement if rotated against the map's bounds.
  ///
  /// [id] is an internally meaningless attribute, but it is passed through to
  /// the emitted [MapEventRotate] and [MapEventMove].
  ///
  /// The emitted [MapEventRotate.source]/[MapEventMove.source] properties will
  /// be [MapEventSource.mapController].
  ///
  /// The operation was successful if both fields of the resulting record are
  /// `true`.
  ({bool moveSuccess, bool rotateSuccess}) rotateAroundPoint(
    double degree, {
    Point<double>? point,
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
  /// The operation was successful if both fields of the resulting record are
  /// `true`.
  ({bool moveSuccess, bool rotateSuccess}) moveAndRotate(
    LatLng center,
    double zoom,
    double degree, {
    String? id,
  });

  /// Move and zoom the map to fit [cameraFit].
  ///
  /// For information about the return value and emitted events, see [move]'s
  /// documentation.
  bool fitCamera(CameraFit cameraFit);

  /// Current [MapCamera]. Accessing the camera from this getter is an
  /// anti-pattern. It is preferable to use [MapCamera.of(context)] in a child
  /// widget of FlutterMap.
  MapCamera get camera;

  /// Move and zoom the map to perfectly fit [bounds], with additional
  /// configurable [options]
  ///
  /// For information about return value meaning and emitted events, see [move]'s
  /// documentation.
  @Deprecated(
    'Prefer `fitCamera` with a CameraFit.bounds() instead. '
    'This method has been changed to use the new `CameraFit` classes which allows different kinds of fit. '
    'This method is deprecated since v6.',
  )
  bool fitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  });

  /// Calculates the appropriate center and zoom level for the map to perfectly
  /// fit [bounds], with additional configurable [options]
  ///
  /// Does not move/zoom the map: see [fitBounds].
  @Deprecated(
    'Prefer `CameraFit.bounds(bounds: bounds).fit(controller.camera)`. '
    'This method is replaced by applying a CameraFit to the MapCamera. '
    'This method is deprecated since v6.',
  )
  CenterZoom centerZoomFitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions options =
        const FitBoundsOptions(padding: EdgeInsets.all(12)),
  });

  /// Convert a screen point (x/y) to its corresponding map coordinate (lat/lng),
  /// based on the map's current properties
  @Deprecated(
    'Prefer `controller.camera.pointToLatLng()`. '
    'This method is now accessible via the camera. '
    'This method is deprecated since v6.',
  )
  LatLng pointToLatLng(Point screenPoint);

  /// Convert a map coordinate (lat/lng) to its corresponding screen point (x/y),
  /// based on the map's current screen positioning
  @Deprecated(
    'Prefer `controller.camera.latLngToScreenPoint()`. '
    'This method is now accessible via the camera. '
    'This method is deprecated since v6.',
  )
  Point<double> latLngToScreenPoint(LatLng mapCoordinate);

  @Deprecated(
    'Prefer `controller.camera.rotatePoint()`. '
    'This method is now accessible via the camera. '
    'This method is deprecated since v6.',
  )
  Point<double> rotatePoint(
    Point mapCenter,
    Point point, {
    bool counterRotation = true,
  });

  /// Current center coordinates
  @Deprecated(
    'Prefer `controller.camera.center`. '
    'This getter is now accessible via the camera. '
    'This getter is deprecated since v6.',
  )
  LatLng get center;

  /// Current outer points/boundaries coordinates
  @Deprecated(
    'Prefer `controller.camera.visibleBounds`. '
    'This getter is now accessible via the camera. '
    'This getter is deprecated since v6.',
  )
  LatLngBounds? get bounds;

  /// Current zoom level
  @Deprecated(
    'Prefer `controller.camera.zoom`. '
    'This getter is now accessible via the camera. '
    'This getter is deprecated since v6.',
  )
  double get zoom;

  /// Current rotation in degrees, where 0° is North
  @Deprecated(
    'Prefer `controller.camera.rotation`. '
    'This getter is now accessible via the camera. '
    'This getter is deprecated since v6.',
  )
  double get rotation;

  /// Dispose of this controller.
  void dispose();
}
