import 'dart:math' as math;

import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

abstract class FrameConstraint {
  const FrameConstraint();

  const factory FrameConstraint.unconstrained() = UnconstrainedFrame._;

  const factory FrameConstraint.containCenter({
    required LatLngBounds bounds,
  }) = ContainFrameCenter._;

  const factory FrameConstraint.contain({
    required LatLngBounds bounds,
  }) = ContainFrame._;

  FlutterMapState? constrain(FlutterMapState mapState);
}

class UnconstrainedFrame extends FrameConstraint {
  const UnconstrainedFrame._();

  @override
  FlutterMapState constrain(FlutterMapState mapState) => mapState;
}

class ContainFrameCenter extends FrameConstraint {
  final LatLngBounds bounds;

  const ContainFrameCenter._({
    required this.bounds,
  });

  @override
  FlutterMapState constrain(FlutterMapState mapState) => mapState.withPosition(
        center: LatLng(
          mapState.center.latitude.clamp(
            bounds.south,
            bounds.north,
          ),
          mapState.center.longitude.clamp(
            bounds.west,
            bounds.east,
          ),
        ),
      );
}

class ContainFrame extends FrameConstraint {
  final LatLngBounds bounds;

  /// Keeps the center of the frame within [bounds].
  const ContainFrame._({
    required this.bounds,
  });

  @override
  FlutterMapState? constrain(FlutterMapState mapState) {
    final testZoom = mapState.zoom;
    final testCenter = mapState.center;

    final nePixel = mapState.project(bounds.northEast, testZoom);
    final swPixel = mapState.project(bounds.southWest, testZoom);

    final halfSize = mapState.size / 2;

    // Find the limits for the map center which would keep the frame within the
    // [latLngBounds].
    final leftOkCenter = math.min(swPixel.x, nePixel.x) + halfSize.x;
    final rightOkCenter = math.max(swPixel.x, nePixel.x) - halfSize.x;
    final topOkCenter = math.min(swPixel.y, nePixel.y) + halfSize.y;
    final botOkCenter = math.max(swPixel.y, nePixel.y) - halfSize.y;

    // Stop if we are zoomed out so far that the frame cannot be translated to
    // stay within [latLngBounds].
    if (leftOkCenter > rightOkCenter || topOkCenter > botOkCenter) return null;

    final centerPix = mapState.project(testCenter, testZoom);
    final newCenterPix = CustomPoint(
      centerPix.x.clamp(leftOkCenter, rightOkCenter),
      centerPix.y.clamp(topOkCenter, botOkCenter),
    );

    if (newCenterPix == centerPix) return mapState;

    return mapState.withPosition(
      center: mapState.unproject(newCenterPix, testZoom),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ContainFrame && other.bounds == bounds;
  }

  @override
  int get hashCode => bounds.hashCode;
}
