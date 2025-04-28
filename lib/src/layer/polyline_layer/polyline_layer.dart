import 'dart:core';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/shared/feature_layer_utils.dart';
import 'package:flutter_map/src/layer/shared/layer_interactivity/internal_hit_detectable.dart';
import 'package:flutter_map/src/layer/shared/layer_projection_simplification/state.dart';
import 'package:flutter_map/src/layer/shared/layer_projection_simplification/widget.dart';
import 'package:flutter_map/src/layer/shared/line_patterns/pixel_hiker.dart';
import 'package:flutter_map/src/misc/extensions.dart';
import 'package:flutter_map/src/misc/offsets.dart';
import 'package:flutter_map/src/misc/simplify.dart';
import 'package:latlong2/latlong.dart';

part 'painter.dart';
part 'polyline.dart';
part 'projected_polyline.dart';

/// A [Polyline] (aka. LineString) layer for [FlutterMap].
@immutable
base class PolylineLayer<R extends Object>
    extends ProjectionSimplificationManagementSupportedWidget {
  /// [Polyline]s to draw
  final List<Polyline<R>> polylines;

  /// Acceptable extent outside of viewport before culling polyline segments
  ///
  /// May need to be increased if the [Polyline.strokeWidth] +
  /// [Polyline.borderStrokeWidth] is large. See the
  /// [online documentation](https://docs.fleaflet.dev/layers/polyline-layer#culling)
  /// for more info.
  ///
  /// Defaults to 10. Set to `null` to disable culling.
  final double? cullingMargin;

  /// {@macro fm.lhn.layerHitNotifier.usage}
  final LayerHitNotifier<R>? hitNotifier;

  /// The minimum radius of the hittable area around each [Polyline] in logical
  /// pixels
  ///
  /// The entire visible area is always hittable, but if the visible area is
  /// smaller than this, then this will be the hittable area.
  ///
  /// Defaults to 10.
  final double minimumHitbox;

  /// Whether polylines should only be drawn/projected onto a single world
  /// instead of potentially being drawn onto adjacent worlds (based on the
  /// shortest distance)
  ///
  /// When set `true` with a CRS which does support
  /// [Crs.replicatesWorldLongitude], polylines will still be repeated across
  /// worlds, but each polyline will only be drawn within one world.
  ///
  /// Enabling this may impact performance by reducing the effectiveness of
  /// culling.
  ///
  /// Defaults to `false`.
  final bool drawInSingleWorld;

  /// Create a new [PolylineLayer] to use as child inside [FlutterMap.children].
  const PolylineLayer({
    super.key,
    required this.polylines,
    this.cullingMargin = 10,
    this.hitNotifier,
    this.minimumHitbox = 10,
    this.drawInSingleWorld = false,
    super.simplificationTolerance,
  }) : super();

  @override
  State<PolylineLayer<R>> createState() => _PolylineLayerState<R>();
}

class _PolylineLayerState<R extends Object> extends State<PolylineLayer<R>>
    with
        ProjectionSimplificationManagement<_ProjectedPolyline<R>, Polyline<R>,
            PolylineLayer<R>> {
  @override
  _ProjectedPolyline<R> projectElement({
    required Projection projection,
    required Polyline<R> element,
  }) =>
      _ProjectedPolyline._fromPolyline(
        projection,
        element,
        widget.drawInSingleWorld,
      );

  @override
  _ProjectedPolyline<R> simplifyProjectedElement({
    required _ProjectedPolyline<R> projectedElement,
    required double tolerance,
  }) =>
      _ProjectedPolyline._(
        polyline: projectedElement.polyline,
        points: simplifyPoints(
          points: projectedElement.points,
          tolerance: tolerance,
          highQuality: true,
        ),
      );

  @override
  List<Polyline<R>> get elements => widget.polylines;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final camera = MapCamera.of(context);

    final culled = widget.cullingMargin == null
        ? simplifiedElements.toList()
        : _aggressivelyCullPolylines(
            projection: camera.crs.projection,
            polylines: simplifiedElements,
            camera: camera,
            cullingMargin: widget.cullingMargin!,
          ).toList();

    return MobileLayerTransformer(
      child: CustomPaint(
        painter: _PolylinePainter(
          polylines: culled,
          camera: camera,
          hitNotifier: widget.hitNotifier,
          minimumHitbox: widget.minimumHitbox,
        ),
        size: camera.size,
      ),
    );
  }

  Iterable<_ProjectedPolyline<R>> _aggressivelyCullPolylines({
    required Projection projection,
    required Iterable<_ProjectedPolyline<R>> polylines,
    required MapCamera camera,
    required double cullingMargin,
  }) sync* {
    final bounds = camera.visibleBounds;
    final margin = cullingMargin / math.pow(2, camera.zoom);

    // The min(-90), max(180), ... are used to get around the limits of LatLng
    // the value cannot be greater or smaller than that
    final boundsAdjusted = LatLngBounds.unsafe(
      west: math.max(LatLngBounds.minLongitude, bounds.west - margin),
      east: math.min(LatLngBounds.maxLongitude, bounds.east + margin),
      south: math.max(LatLngBounds.minLatitude, bounds.south - margin),
      north: math.min(LatLngBounds.maxLatitude, bounds.north + margin),
    );

    // segment is visible
    final projBounds = Rect.fromPoints(
      projection.project(boundsAdjusted.southWest),
      projection.project(boundsAdjusted.northEast),
    );

    final (xWest, _) = projection.projectXY(const LatLng(0, -180));
    final (xEast, _) = projection.projectXY(const LatLng(0, 180));
    for (final projectedPolyline in polylines) {
      final polyline = projectedPolyline.polyline;
      final boundingBox = polyline.boundingBox;

      /// Check if the camera and the polyline overlap, latitude-wise.
      bool isOverlappingLatitude() {
        if (boundsAdjusted.north < boundingBox.south) {
          return false;
        }
        if (boundsAdjusted.south > boundingBox.north) {
          return false;
        }
        return true;
      }

      /// Check if the camera and the polyline overlap, longitude-wise.
      bool isOverlappingLongitude() {
        if (boundsAdjusted.east < boundingBox.west) {
          return false;
        }
        if (boundsAdjusted.west > boundingBox.east) {
          return false;
        }
        return true;
      }

      /// Check if the camera longitude bounds are reliable, world-wise.
      bool areLongitudeBoundsReliable() {
        if (boundsAdjusted.east == LatLngBounds.maxLongitude) {
          return false;
        }
        if (boundsAdjusted.west == LatLngBounds.minLongitude) {
          return false;
        }
        return true;
      }

      // Test bounding boxes to avoid potentially expensive aggressive culling
      // when none of the line is visible
      // First check, bullet-proof, focusing on latitudes.
      if (!isOverlappingLatitude()) continue;

      // Gradient polylines cannot be easily segmented
      if (polyline.gradientColors != null) {
        yield projectedPolyline;
        continue;
      }

      // TODO: think about how to cull polylines in a forced "drawInSingleWorld".
      // As what may be culled in a world may not be culled in a next world.
      if (widget.drawInSingleWorld) {
        yield projectedPolyline;
        continue;
      }

      /// Returns true if the points stretch on different versions of the world.
      bool stretchesBeyondTheLimits() {
        for (final point in projectedPolyline.points) {
          if (point.dx > xEast || point.dx < xWest) {
            return true;
          }
        }
        return false;
      }

      // TODO: think about how to cull polylines that go beyond -180/180.
      // As the notions of projected west/east as min/max are not reliable.
      if (stretchesBeyondTheLimits()) {
        yield projectedPolyline;
        continue;
      }

      // TODO: think about how to cull when the camera bounds go beyond -180/180.
      if (!areLongitudeBoundsReliable()) {
        yield projectedPolyline;
        continue;
      }

      // Test bounding boxes to avoid potentially expensive aggressive culling
      // when none of the line is visible. Here, focusing on longitudes.
      if (!isOverlappingLongitude()) continue;

      // pointer that indicates the start of the visible polyline segment
      int start = -1;
      bool containsSegment = false;
      for (int i = 0; i < projectedPolyline.points.length - 1; i++) {
        // Current segment (p1, p2).
        final p1 = projectedPolyline.points[i];
        final p2 = projectedPolyline.points[i + 1];

        containsSegment =
            projBounds.aabbContainsLine(p1.dx, p1.dy, p2.dx, p2.dy);
        if (containsSegment) {
          if (start == -1) {
            start = i;
          }
        } else {
          // If we cannot see this segment but have seen previous ones, flush the last polyline fragment.
          if (start != -1) {
            yield _ProjectedPolyline._(
              polyline: polyline,
              points: projectedPolyline.points.sublist(start, i + 1),
            );

            // Reset start.
            start = -1;
          }
        }
      }

      // If the last segment was visible push that last visible polyline
      // fragment, which may also be the entire polyline if `start == 0`.
      if (containsSegment) {
        yield start == 0
            ? projectedPolyline
            : _ProjectedPolyline._(
                polyline: polyline,
                // Special case: the entire polyline is visible
                points: projectedPolyline.points.sublist(start),
              );
      }
    }
  }
}
