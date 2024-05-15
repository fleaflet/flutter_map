import 'dart:core';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/misc/line_patterns/pixel_hiker.dart';
import 'package:flutter_map/src/misc/offsets.dart';
import 'package:flutter_map/src/misc/simplify.dart';
import 'package:latlong2/latlong.dart';

part 'painter.dart';
part 'polyline.dart';
part 'projected_polyline.dart';

/// A [Polyline] (aka. LineString) layer for [FlutterMap].
@immutable
class PolylineLayer<R extends Object> extends StatefulWidget {
  /// [Polyline]s to draw
  final List<Polyline<R>> polylines;

  /// Acceptable extent outside of viewport before culling polyline segments
  ///
  /// May need to be increased if the [Polyline.strokeWidth] +
  /// [Polyline.borderStrokeWidth] is large. See online documentation for more
  /// information.
  ///
  /// Defaults to 10. Set to `null` to disable culling.
  final double? cullingMargin;

  /// Distance between two neighboring polyline points, in logical pixels scaled
  /// to floored zoom
  ///
  /// Increasing this value results in points further apart being collapsed and
  /// thus more simplified polylines. Higher values improve performance at the
  /// cost of visual fidelity and vice versa.
  ///
  /// Defaults to 0.4. Set to 0 to disable simplification.
  final double simplificationTolerance;

  /// A notifier to be notified when a hit test occurs on the layer
  ///
  /// Notified with a [LayerHitResult] if any polylines are hit, otherwise
  /// notified with `null`.
  ///
  /// Hit testing still occurs even if this is `null`.
  ///
  /// See online documentation for more detailed usage instructions. See the
  /// example project for an example implementation.
  final LayerHitNotifier<R>? hitNotifier;

  /// The minimum radius of the hittable area around each [Polyline] in logical
  /// pixels
  ///
  /// The entire visible area is always hittable, but if the visible area is
  /// smaller than this, then this will be the hittable area.
  ///
  /// Defaults to 10.
  final double minimumHitbox;

  /// Create a new [PolylineLayer] to use as child inside [FlutterMap.children].
  const PolylineLayer({
    super.key,
    required this.polylines,
    this.cullingMargin = 10,
    this.simplificationTolerance = 0.4,
    this.hitNotifier,
    this.minimumHitbox = 10,
  }) : assert(
          simplificationTolerance >= 0,
          'simplificationTolerance cannot be negative: $simplificationTolerance',
        );

  @override
  State<PolylineLayer<R>> createState() => _PolylineLayerState<R>();
}

class _PolylineLayerState<R extends Object> extends State<PolylineLayer<R>> {
  List<_ProjectedPolyline<R>>? _cachedProjectedPolylines;
  final _cachedSimplifiedPolylines = <int, List<_ProjectedPolyline<R>>>{};

  double? _devicePixelRatio;

  @override
  void didUpdateWidget(PolylineLayer<R> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listEquals(oldWidget.polylines, widget.polylines)) {
      // If the polylines have changed, then both the projections and the
      // projection-dependendent simplifications must be invalidated
      _cachedProjectedPolylines = null;
      _cachedSimplifiedPolylines.clear();
    } else if (oldWidget.simplificationTolerance !=
        widget.simplificationTolerance) {
      // If only the simplification tolerance has changed, this does not affect
      // the projections (as that is done before simplification), so only
      // invalidate the simplifications
      _cachedSimplifiedPolylines.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    final projected = _cachedProjectedPolylines ??= List.generate(
      widget.polylines.length,
      (i) => _ProjectedPolyline._fromPolyline(
        camera.crs.projection,
        widget.polylines[i],
      ),
      growable: false,
    );

    late final List<_ProjectedPolyline<R>> simplified;
    if (widget.simplificationTolerance == 0) {
      simplified = projected;
    } else {
      // If the DPR has changed, invalidate the simplification cache
      final newDPR = MediaQuery.devicePixelRatioOf(context);
      if (newDPR != _devicePixelRatio) {
        _devicePixelRatio = newDPR;
        _cachedSimplifiedPolylines.clear();
      }

      simplified = _cachedSimplifiedPolylines[camera.zoom.floor()] ??=
          _computeZoomLevelSimplification(
        camera: camera,
        polylines: projected,
        pixelTolerance: widget.simplificationTolerance,
        devicePixelRatio: newDPR,
      );
    }

    final culled = widget.cullingMargin == null
        ? simplified
        : _aggressivelyCullPolylines(
            projection: camera.crs.projection,
            polylines: simplified,
            camera: camera,
            cullingMargin: widget.cullingMargin!,
          );

    return MobileLayerTransformer(
      child: CustomPaint(
        painter: _PolylinePainter(
          polylines: culled,
          camera: camera,
          hitNotifier: widget.hitNotifier,
          minimumHitbox: widget.minimumHitbox,
        ),
        size: Size(camera.size.x, camera.size.y),
      ),
    );
  }

  List<_ProjectedPolyline<R>> _aggressivelyCullPolylines({
    required Projection projection,
    required List<_ProjectedPolyline<R>> polylines,
    required MapCamera camera,
    required double cullingMargin,
  }) {
    final culledPolylines = <_ProjectedPolyline<R>>[];

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
    final projBounds = Bounds(
      projection.project(boundsAdjusted.southWest),
      projection.project(boundsAdjusted.northEast),
    );

    for (final projectedPolyline in polylines) {
      final polyline = projectedPolyline.polyline;

      // Gradient poylines cannot be easily segmented
      if (polyline.gradientColors != null) {
        culledPolylines.add(projectedPolyline);
        continue;
      }

      // pointer that indicates the start of the visible polyline segment
      int start = -1;
      bool containsSegment = false;
      for (int i = 0; i < projectedPolyline.points.length - 1; i++) {
        // Current segment (p1, p2).
        final p1 = projectedPolyline.points[i];
        final p2 = projectedPolyline.points[i + 1];

        containsSegment = projBounds.aabbContainsLine(p1.x, p1.y, p2.x, p2.y);
        if (containsSegment) {
          if (start == -1) {
            start = i;
          }
        } else {
          // If we cannot see this segment but have seen previous ones, flush the last polyline fragment.
          if (start != -1) {
            culledPolylines.add(
              _ProjectedPolyline._(
                polyline: polyline,
                points: projectedPolyline.points.sublist(start, i + 1),
              ),
            );

            // Reset start.
            start = -1;
          }
        }
      }

      // If the last segment was visible push that last visible polyline
      // fragment, which may also be the entire polyline if `start == 0`.
      if (containsSegment) {
        culledPolylines.add(
          start == 0
              ? projectedPolyline
              : _ProjectedPolyline._(
                  polyline: polyline,
                  // Special case: the entire polyline is visible
                  points: projectedPolyline.points.sublist(start),
                ),
        );
      }
    }

    return culledPolylines;
  }

  List<_ProjectedPolyline<R>> _computeZoomLevelSimplification({
    required MapCamera camera,
    required List<_ProjectedPolyline<R>> polylines,
    required double pixelTolerance,
    required double devicePixelRatio,
  }) {
    final tolerance = getEffectiveSimplificationTolerance(
      crs: camera.crs,
      zoom: camera.zoom.floor(),
      pixelTolerance: pixelTolerance,
      devicePixelRatio: devicePixelRatio,
    );

    return List<_ProjectedPolyline<R>>.generate(
      polylines.length,
      (i) {
        final polyline = polylines[i];

        return _ProjectedPolyline._(
          polyline: polyline.polyline,
          points: simplifyPoints(
            points: polyline.points,
            tolerance: tolerance,
            highQuality: true,
          ),
        );
      },
      growable: false,
    );
  }
}
