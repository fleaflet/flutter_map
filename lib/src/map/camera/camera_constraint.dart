import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Describes a boundary for a [MapCamera], that cannot be exceeded by movement
///
/// This separate from constraints that may be imposed by the chosen CRS.
///
/// Positioning is handled by [CameraFit].
@immutable
abstract class CameraConstraint {
  /// Describes a boundary for a [MapCamera], that cannot be exceeded by movement
  ///
  /// This separate from constraints that may be imposed by the chosen CRS.
  ///
  /// Positioning is handled by [CameraFit].
  const CameraConstraint();

  /// Does not apply any constraint
  const factory CameraConstraint.unconstrained() = UnconstrainedCamera._;

  /// Constrains the center coordinate of the camera to within [bounds]
  ///
  /// Areas outside of [bounds] are likely to be visible. To instead constrain
  /// by the edges of the camera, use [CameraConstraint.contain].
  const factory CameraConstraint.containCenter({
    required LatLngBounds bounds,
  }) = ContainCameraCenter._;

  /// Constrains the edges of the camera to within [bounds]
  ///
  /// To instead constrain the center coordinate of the camera to these bounds,
  /// use [CameraConstraint.containCenter].
  const factory CameraConstraint.contain({
    required LatLngBounds bounds,
  }) = ContainCamera._;

  /// Create a new constrained camera based off the current [camera]
  ///
  /// May return `null` if no appropriate camera could be generated by movement,
  /// for example because the camera was zoomed too far out.
  MapCamera? constrain(MapCamera camera);
}

/// Does not apply any constraint to a [MapCamera]
///
/// See [CameraConstraint] for more information.
@immutable
class UnconstrainedCamera extends CameraConstraint {
  const UnconstrainedCamera._();

  @override
  MapCamera constrain(MapCamera camera) => camera;
}

/// Constrains the center coordinate of the camera to within [bounds]
///
/// Areas outside of [bounds] are likely to be visible. To instead constrain
/// by the edges of the camera, use [ContainCamera].
///
/// See [CameraConstraint] for more information.
@immutable
class ContainCameraCenter extends CameraConstraint {
  const ContainCameraCenter._({required this.bounds});

  /// The bounding box
  final LatLngBounds bounds;

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

  @override
  bool operator ==(Object other) {
    return other is ContainCameraCenter && other.bounds == bounds;
  }

  @override
  int get hashCode => bounds.hashCode;
}

/// Constrains the edges of the camera to within [bounds]
///
/// To instead constrain the center coordinate of the camera to these bounds,
/// use [ContainCameraCenter].
///
/// See [CameraConstraint] for more information.
@immutable
class ContainCamera extends CameraConstraint {
  const ContainCamera._({required this.bounds});

  /// The bounding box
  final LatLngBounds bounds;

  @override
  MapCamera? constrain(MapCamera camera) {
    final testZoom = camera.zoom;
    final testCenter = camera.center;

    final nePixel = camera.project(bounds.northEast, testZoom);
    final swPixel = camera.project(bounds.southWest, testZoom);

    final halfSize = camera.size / 2;

    // Find the limits for the map center which would keep the camera within the
    // [latLngBounds].
    final leftOkCenter = math.min(swPixel.dx, nePixel.dx) + halfSize.dx;
    final rightOkCenter = math.max(swPixel.dx, nePixel.dx) - halfSize.dx;
    final topOkCenter = math.min(swPixel.dy, nePixel.dy) + halfSize.dy;
    final botOkCenter = math.max(swPixel.dy, nePixel.dy) - halfSize.dy;

    // Stop if we are zoomed out so far that the camera cannot be translated to
    // stay within [latLngBounds].
    if (leftOkCenter > rightOkCenter || topOkCenter > botOkCenter) return null;

    final centerPix = camera.project(testCenter, testZoom);
    final newCenterPix = Offset(
      centerPix.dx.clamp(leftOkCenter, rightOkCenter),
      centerPix.dy.clamp(topOkCenter, botOkCenter),
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
