import 'dart:math' as math;

import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/map/camera.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:latlong2/latlong.dart';

/// Describes a limit for the map's camera. This separate from constraints that
/// may be imposed by the chosen CRS.
abstract class CameraConstraint {
  const CameraConstraint();

  /// Does not apply any constraint to the map movement. Note that the CRS
  /// system of the map may still constrain the camera.
  const factory CameraConstraint.unconstrained() = UnconstrainedCamera._;

  /// Limits the camera such that the center point of the camera remains within
  /// [bounds]. This does not prevent points outside of [bounds] from being
  /// shown, to achieve that you must use [ContainCamera].
  const factory CameraConstraint.containCenter({
    required LatLngBounds bounds,
  }) = ContainCameraCenter._;

  /// Limits the camera such that no point outside of the [bounds] will become
  /// visible.
  const factory CameraConstraint.contain({
    required LatLngBounds bounds,
  }) = ContainCamera._;

  MapCamera? constrain(MapCamera camera);
}

/// Allows the map to be moved without constraints. The CRS system of the map
/// may still resrict map movement to prevent invalid positions.
class UnconstrainedCamera extends CameraConstraint {
  const UnconstrainedCamera._();

  @override
  MapCamera constrain(MapCamera camera) => camera;
}

/// Limits the camera such that the center point of the camera remains within
/// [bounds]. This does not prevent points outside of [bounds] from being
/// shown, to achieve that you must use [ContainCamera].
class ContainCameraCenter extends CameraConstraint {
  final LatLngBounds bounds;

  const ContainCameraCenter._({
    required this.bounds,
  });

  /// Returns a new [MapCamera] with the center point contained within
  /// [bounds].
  @override
  MapCamera constrain(MapCamera camera) => camera.withPosition(
        center: LatLng(
          camera.center.latitude.clamp(
            bounds.south,
            bounds.north,
          ),
          camera.center.longitude.clamp(
            bounds.west,
            bounds.east,
          ),
        ),
      );
}

/// Limits the camera such that no point outside of the [bounds] will become
/// visible.
class ContainCamera extends CameraConstraint {
  final LatLngBounds bounds;

  const ContainCamera._({
    required this.bounds,
  });

  /// Tries to determine a movement such that the [camera] only contains points
  /// within [bounds]. If no movement is necessary the provided [camera] is
  /// returned. If remaining within the [bounds] solely via movement is not
  /// possible, because the camera is zoomed too far out, null is returned.
  @override
  MapCamera? constrain(MapCamera camera) {
    final testZoom = camera.zoom;
    final testCenter = camera.center;

    final nePixel = camera.project(bounds.northEast, testZoom);
    final swPixel = camera.project(bounds.southWest, testZoom);

    final halfSize = camera.size / 2;

    // Find the limits for the map center which would keep the camera within the
    // [latLngBounds].
    final leftOkCenter = math.min(swPixel.x, nePixel.x) + halfSize.x;
    final rightOkCenter = math.max(swPixel.x, nePixel.x) - halfSize.x;
    final topOkCenter = math.min(swPixel.y, nePixel.y) + halfSize.y;
    final botOkCenter = math.max(swPixel.y, nePixel.y) - halfSize.y;

    // Stop if we are zoomed out so far that the camera cannot be translated to
    // stay within [latLngBounds].
    if (leftOkCenter > rightOkCenter || topOkCenter > botOkCenter) return null;

    final centerPix = camera.project(testCenter, testZoom);
    final newCenterPix = CustomPoint(
      centerPix.x.clamp(leftOkCenter, rightOkCenter),
      centerPix.y.clamp(topOkCenter, botOkCenter),
    );

    if (newCenterPix == centerPix) return camera;

    return camera.withPosition(
      center: camera.unproject(newCenterPix, testZoom),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ContainCamera && other.bounds == bounds;
  }

  @override
  int get hashCode => bounds.hashCode;
}
