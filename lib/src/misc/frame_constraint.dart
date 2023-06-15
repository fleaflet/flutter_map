import 'dart:math' as math;

import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/map/flutter_map_frame.dart';
import 'package:flutter_map/src/misc/point.dart';
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

  MapFrame? constrain(MapFrame mapFrame);
}

class UnconstrainedFrame extends FrameConstraint {
  const UnconstrainedFrame._();

  @override
  MapFrame constrain(MapFrame mapFrame) => mapFrame;
}

class ContainFrameCenter extends FrameConstraint {
  final LatLngBounds bounds;

  const ContainFrameCenter._({
    required this.bounds,
  });

  @override
  MapFrame constrain(MapFrame mapFrame) => mapFrame.withPosition(
        center: LatLng(
          mapFrame.center.latitude.clamp(
            bounds.south,
            bounds.north,
          ),
          mapFrame.center.longitude.clamp(
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
  MapFrame? constrain(MapFrame mapFrame) {
    final testZoom = mapFrame.zoom;
    final testCenter = mapFrame.center;

    final nePixel = mapFrame.project(bounds.northEast, testZoom);
    final swPixel = mapFrame.project(bounds.southWest, testZoom);

    final halfSize = mapFrame.size / 2;

    // Find the limits for the map center which would keep the frame within the
    // [latLngBounds].
    final leftOkCenter = math.min(swPixel.x, nePixel.x) + halfSize.x;
    final rightOkCenter = math.max(swPixel.x, nePixel.x) - halfSize.x;
    final topOkCenter = math.min(swPixel.y, nePixel.y) + halfSize.y;
    final botOkCenter = math.max(swPixel.y, nePixel.y) - halfSize.y;

    // Stop if we are zoomed out so far that the frame cannot be translated to
    // stay within [latLngBounds].
    if (leftOkCenter > rightOkCenter || topOkCenter > botOkCenter) return null;

    final centerPix = mapFrame.project(testCenter, testZoom);
    final newCenterPix = CustomPoint(
      centerPix.x.clamp(leftOkCenter, rightOkCenter),
      centerPix.y.clamp(topOkCenter, botOkCenter),
    );

    if (newCenterPix == centerPix) return mapFrame;

    return mapFrame.withPosition(
      center: mapFrame.unproject(newCenterPix, testZoom),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ContainFrame && other.bounds == bounds;
  }

  @override
  int get hashCode => bounds.hashCode;
}
