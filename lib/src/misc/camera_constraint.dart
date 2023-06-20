import 'dart:math' as math;

import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/map/camera.dart';
import 'package:flutter_map/src/misc/point.dart';
import 'package:latlong2/latlong.dart';

abstract class CameraConstraint {
  const CameraConstraint();

  const factory CameraConstraint.unconstrained() = UnconstrainedCamera._;

  const factory CameraConstraint.containCenter({
    required LatLngBounds bounds,
  }) = ContainCameraCenter._;

  const factory CameraConstraint.contain({
    required LatLngBounds bounds,
  }) = ContainCamera._;

  MapCamera? constrain(MapCamera camera);
}

class UnconstrainedCamera extends CameraConstraint {
  const UnconstrainedCamera._();

  @override
  MapCamera constrain(MapCamera camera) => camera;
}

class ContainCameraCenter extends CameraConstraint {
  final LatLngBounds bounds;

  const ContainCameraCenter._({
    required this.bounds,
  });

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

class ContainCamera extends CameraConstraint {
  final LatLngBounds bounds;

  /// Keeps the center of the camera within [bounds].
  const ContainCamera._({
    required this.bounds,
  });

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
