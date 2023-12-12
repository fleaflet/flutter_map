import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/misc/simplify.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:polylabel/polylabel.dart'; // conflict with Path from UI

part 'label.dart';
part 'painter.dart';
part 'polygon.dart';

/// A polygon layer for [FlutterMap].
@immutable
class PolygonLayer extends StatefulWidget {
  /// [Polygon]s to draw
  final List<Polygon> polygons;

  /// Whether to cull polygons and polygon sections that are outside of the
  /// viewport
  ///
  /// Defaults to `true`.
  final bool polygonCulling;

  /// Distance between two mergeable polygon points, in decimal degrees scaled
  /// to floored zoom
  ///
  /// Increasing results in a more jagged, less accurate simplification, with
  /// improved performance; and vice versa.
  ///
  /// Note that this value is internally scaled using the current map zoom, to
  /// optimize visual performance in conjunction with improved performance with
  /// culling.
  ///
  /// Defaults to 0.5. Set to 0 to disable simplification.
  final double simplificationTolerance;

  /// Whether to draw per-polygon labels
  ///
  /// Defaults to `true`.
  final bool polygonLabels;

  /// Whether to draw labels last and thus over all the polygons
  ///
  /// Defaults to `false`.
  final bool drawLabelsLast;

  /// Create a new [PolygonLayer] for the [FlutterMap] widget.
  const PolygonLayer({
    super.key,
    required this.polygons,
    this.polygonCulling = true,
    this.simplificationTolerance = 0.5,
    this.polygonLabels = true,
    this.drawLabelsLast = false,
  });

  @override
  State<PolygonLayer> createState() => _PolygonLayerState();
}

class _PolygonLayerState extends State<PolygonLayer> {
  final _cachedSimplifiedPolygons = <int, List<Polygon>>{};

  @override
  void didUpdateWidget(PolygonLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // IF old yes & new no, clear
    // IF old no & new yes, compute
    // IF old no & new no, nothing
    // IF old yes & new yes & (different tolerance | different lines), both
    //    otherwise, nothing
    if (oldWidget.simplificationTolerance != 0 &&
        widget.simplificationTolerance != 0 &&
        (!listEquals(oldWidget.polygons, widget.polygons) ||
            oldWidget.simplificationTolerance !=
                widget.simplificationTolerance)) {
      _cachedSimplifiedPolygons.clear();
      _computeZoomLevelSimplification(MapCamera.of(context).zoom.floor());
    } else if (oldWidget.simplificationTolerance != 0 &&
        widget.simplificationTolerance == 0) {
      _cachedSimplifiedPolygons.clear();
    } else if (oldWidget.simplificationTolerance == 0 &&
        widget.simplificationTolerance != 0) {
      _computeZoomLevelSimplification(MapCamera.of(context).zoom.floor());
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    final simplified = widget.simplificationTolerance == 0
        ? widget.polygons
        : _computeZoomLevelSimplification(camera.zoom.floor());

    final culled = !widget.polygonCulling
        ? simplified
        : simplified
            .where((p) => p.boundingBox.isOverlapping(camera.visibleBounds))
            .toList();

    return MobileLayerTransformer(
      child: CustomPaint(
        painter: PolygonPainter(
          polygons: culled,
          camera: camera,
          polygonLabels: widget.polygonLabels,
          drawLabelsLast: widget.drawLabelsLast,
        ),
        size: Size(camera.size.x, camera.size.y),
      ),
    );
  }

  List<Polygon> _computeZoomLevelSimplification(int zoom) =>
      _cachedSimplifiedPolygons[zoom] ??= widget.polygons
          .map(
            (polygon) => polygon.copyWithNewPoints(
              simplify(
                polygon.points,
                widget.simplificationTolerance / math.pow(2, zoom),
                highestQuality: true,
              ),
            ),
          )
          .toList();
}
