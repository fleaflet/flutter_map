import 'dart:core';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
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
  /// If a notifier is not provided, hit testing is not performed.
  ///
  /// Notified with a [LayerHitResult] if any polylines are hit, otherwise
  /// notified with `null`.
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
  });

  @override
  State<PolylineLayer<R>> createState() => _PolylineLayerState<R>();
}

class _PolylineLayerState<R extends Object> extends State<PolylineLayer<R>> {
  List<_ProjectedPolyline>? _cachedProjectedPolylines;
  final _cachedSimplifiedPolylines = <int, List<_ProjectedPolyline>>{};

  final _culledPolylines =
      <_ProjectedPolyline>[]; // Avoids repetitive memory reallocation

  @override
  void didUpdateWidget(PolylineLayer<R> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reuse cache
    if (widget.simplificationTolerance != 0 &&
        oldWidget.simplificationTolerance == widget.simplificationTolerance &&
        listEquals(oldWidget.polylines, widget.polylines)) return;

    _cachedSimplifiedPolylines.clear();
    _cachedProjectedPolylines = null;
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

    final simplified = widget.simplificationTolerance == 0
        ? projected
        : _cachedSimplifiedPolylines[camera.zoom.floor()] ??=
            _computeZoomLevelSimplification(
            camera: camera,
            polylines: projected,
            pixelTolerance: widget.simplificationTolerance,
            devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
          );

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

  List<_ProjectedPolyline> _aggressivelyCullPolylines({
    required Projection projection,
    required List<_ProjectedPolyline> polylines,
    required MapCamera camera,
    required double cullingMargin,
  }) {
    _culledPolylines.clear();

    final bounds = camera.visibleBounds;
    final margin = cullingMargin / math.pow(2, camera.zoom);

    // The min(-90), max(180), ... are used to get around the limits of LatLng
    // the value cannot be greater or smaller than that
    final boundsAdjusted = LatLngBounds(
      LatLng(
        math.max(-90, bounds.southWest.latitude - margin),
        math.max(-180, bounds.southWest.longitude - margin),
      ),
      LatLng(
        math.min(90, bounds.northEast.latitude + margin),
        math.min(180, bounds.northEast.longitude + margin),
      ),
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
        _culledPolylines.add(projectedPolyline);
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
            _culledPolylines.add(_ProjectedPolyline._(
              polyline: polyline,
              points: projectedPolyline.points.sublist(start, i + 1),
            ));

            // Reset start.
            start = -1;
          }
        }
      }

      // If the last segment was visible push that last visible polyline
      // fragment, which may also be the entire polyline if `start == 0`.
      if (containsSegment) {
        _culledPolylines.add(
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

    return _culledPolylines;
  }

  static List<_ProjectedPolyline> _computeZoomLevelSimplification({
    required MapCamera camera,
    required List<_ProjectedPolyline> polylines,
    required double pixelTolerance,
    required double devicePixelRatio,
  }) {
    final tolerance = getEffectiveSimplificationTolerance(
      crs: camera.crs,
      zoom: camera.zoom.floor(),
      pixelTolerance: pixelTolerance,
      devicePixelRatio: devicePixelRatio,
    );

    return List<_ProjectedPolyline>.generate(
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
