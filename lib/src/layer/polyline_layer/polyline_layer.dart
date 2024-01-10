import 'dart:core';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/misc/simplify.dart';
import 'package:latlong2/latlong.dart';

part 'hit.dart';
part 'painter.dart';
part 'polyline.dart';

@immutable
class PolylineLayer<R extends Object> extends StatefulWidget {
  /// [Polyline]s to draw
  final List<Polyline<R>> polylines;

  /// Acceptable extent outside of viewport before culling polyline segments
  ///
  /// May need to be increased if the [Polyline.borderStrokeWidth] is large.
  ///
  /// Defaults to 0: cull aggressively. Set to `null` to disable culling.
  final double? cullingMargin;

  /// Distance between two mergeable polyline points, in decimal degrees scaled
  /// to floored zoom
  ///
  /// Increasing results in a more jagged, less accurate simplification, with
  /// improved performance; and vice versa.
  ///
  /// Note that this value is internally scaled using the current map zoom, to
  /// optimize visual performance in conjunction with improved performance with
  /// culling.
  ///
  /// Defaults to 1. Set to `null` to disable simplification.
  final double? simplificationTolerance;

  /// A notifier to be notified when a hit test occurs on the layer
  ///
  /// If a notifier is not provided, hit testing is not performed.
  ///
  /// Notified with a [PolylineHit] if any [Polyline]s are hit, otherwise
  /// notified with `null`.
  ///
  /// Note that a hover event is included as a hit event. If an expensive
  /// operation is required on hover, check for equality between the new and old
  /// [PolylineHit.hitValues], and avoid doing heavy work if they are the same.
  ///
  /// See online documentation for more detailed usage instructions. See the
  /// example project for an example implementation.
  final PolylineHitNotifier<R>? hitNotifier;

  /// The minimum radius of the hittable area around each [Polyline] in logical
  /// pixels
  ///
  /// The entire visible area is always hittable, but if the visible area is
  /// smaller than this, then this will be the hittable area.
  ///
  /// Defaults to 10.
  final double minimumHitbox;

  const PolylineLayer({
    super.key,
    required this.polylines,
    this.cullingMargin = 0,
    this.simplificationTolerance = 1,
    this.hitNotifier,
    this.minimumHitbox = 10,
  });

  @override
  State<PolylineLayer<R>> createState() => _PolylineLayerState<R>();
}

class _PolylineLayerState<R extends Object> extends State<PolylineLayer<R>> {
  final _cachedSimplifiedPolylines = <int, List<Polyline<R>>>{};

  final _culledPolylines =
      <Polyline<R>>[]; // Avoids repetitive memory reallocation

  @override
  void didUpdateWidget(PolylineLayer<R> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // IF old yes & new no, clear
    // IF old no & new yes, compute
    // IF old no & new no, nothing
    // IF old yes & new yes & (different tolerance | different lines), both
    //    otherwise, nothing
    if (oldWidget.simplificationTolerance != null &&
        widget.simplificationTolerance != null &&
        (!listEquals(oldWidget.polylines, widget.polylines) ||
            oldWidget.simplificationTolerance !=
                widget.simplificationTolerance)) {
      _cachedSimplifiedPolylines.clear();
      _computeZoomLevelSimplification(MapCamera.of(context).zoom.floor());
    } else if (oldWidget.simplificationTolerance != null &&
        widget.simplificationTolerance == null) {
      _cachedSimplifiedPolylines.clear();
    } else if (oldWidget.simplificationTolerance == null &&
        widget.simplificationTolerance != null) {
      _computeZoomLevelSimplification(MapCamera.of(context).zoom.floor());
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    return MobileLayerTransformer(
      child: CustomPaint(
        painter: PolylinePainter(
          polylines: _aggressivelyCullPolylines(
            polylines: widget.simplificationTolerance == null
                ? widget.polylines
                : _computeZoomLevelSimplification(camera.zoom.floor()),
            camera: camera,
            cullingMargin: widget.cullingMargin,
          ),
          camera: camera,
          hitNotifier: widget.hitNotifier,
          minimumHitbox: widget.minimumHitbox,
        ),
        size: Size(camera.size.x, camera.size.y),
      ),
    );
  }

  List<Polyline<R>> _computeZoomLevelSimplification(int zoom) =>
      _cachedSimplifiedPolylines[zoom] ??= widget.polylines
          .map(
            (polyline) => polyline.copyWithNewPoints(
              simplify(
                polyline.points,
                widget.simplificationTolerance! / math.pow(2, zoom),
                highestQuality: true,
              ),
            ),
          )
          .toList();

  List<Polyline<R>> _aggressivelyCullPolylines({
    required List<Polyline<R>> polylines,
    required MapCamera camera,
    required double? cullingMargin,
  }) {
    if (cullingMargin == null) return polylines;

    _culledPolylines.clear();

    final bounds = camera.visibleBounds;
    final margin = cullingMargin / math.pow(2, camera.zoom.floorToDouble());
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

    for (final polyline in polylines) {
      // Gradient poylines cannot be easily segmented
      if (polyline.gradientColors != null) {
        _culledPolylines.add(polyline);
        continue;
      }
      // pointer that indicates the start of the visible polyline segment
      int start = -1;
      bool fullyVisible = true;
      for (int i = 0; i < polyline.points.length - 1; i++) {
        //current pair
        final p1 = polyline.points[i];
        final p2 = polyline.points[i + 1];

        // segment is visible
        if (Bounds(
          math.Point(
            boundsAdjusted.southWest.longitude,
            boundsAdjusted.southWest.latitude,
          ),
          math.Point(
            boundsAdjusted.northEast.longitude,
            boundsAdjusted.northEast.latitude,
          ),
        ).aabbContainsLine(
            p1.longitude, p1.latitude, p2.longitude, p2.latitude)) {
          // segment is visible
          if (start == -1) {
            start = i;
          }
          if (!fullyVisible && i == polyline.points.length - 2) {
            final segment = polyline.points.sublist(start, i + 2);
            _culledPolylines.add(polyline.copyWithNewPoints(segment));
          }
        } else {
          fullyVisible = false;
          // if we cannot see the segment, then reset start
          if (start != -1) {
            // partial start
            final segment = polyline.points.sublist(start, i + 1);
            _culledPolylines.add(polyline.copyWithNewPoints(segment));
            start = -1;
          }
          if (start != -1) {
            start = i;
          }
        }
      }

      if (fullyVisible) _culledPolylines.add(polyline);
    }

    return _culledPolylines;
  }
}
