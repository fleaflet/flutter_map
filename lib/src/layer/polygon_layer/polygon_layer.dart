import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/misc/offsets.dart';
import 'package:flutter_map/src/misc/simplify.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:polylabel/polylabel.dart'; // conflict with Path from UI

part 'label.dart';
part 'painter.dart';
part 'polygon.dart';

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
  List<_ProjectedPolygon>? _cachedProjectedPolygons;
  double? _effectiveTolerance;
  final _cachedSimplifiedPolygons = <int, List<_ProjectedPolygon>>{};

  @override
  void didUpdateWidget(PolygonLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.simplificationTolerance != 0 &&
        oldWidget.simplificationTolerance == widget.simplificationTolerance &&
        listEquals(oldWidget.polygons, widget.polygons)) {
      // Reuse cache.
      return;
    }

    _cachedSimplifiedPolygons.clear();
    _cachedProjectedPolygons = null;
    _effectiveTolerance = null;
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    final projected = _cachedProjectedPolygons ??= List.generate(
      widget.polygons.length,
      (i) => _ProjectedPolygon.fromPolygon(
        camera.crs.projection,
        widget.polygons[i],
      ),
      growable: false,
    );
    final simplificationTolerance = _effectiveTolerance ??=
        getEffectiveSimplificationTolerance(
            camera.crs.projection, widget.simplificationTolerance);

    final zoom = camera.zoom.floor();

    final simplified = widget.simplificationTolerance == 0
        ? projected
        : _cachedSimplifiedPolygons[zoom] ??= _computeZoomLevelSimplification(
            projected,
            simplificationTolerance,
            zoom,
          );

    final culled = !widget.polygonCulling
        ? simplified
        : simplified
            .where(
              (p) => p.polygon.boundingBox.isOverlapping(camera.visibleBounds),
            )
            .toList();

    return MobileLayerTransformer(
      child: CustomPaint(
        painter: _PolygonPainter(
          polygons: culled,
          camera: camera,
          polygonLabels: widget.polygonLabels,
          drawLabelsLast: widget.drawLabelsLast,
        ),
        size: Size(camera.size.x, camera.size.y),
      ),
    );
  }

  static List<_ProjectedPolygon> _computeZoomLevelSimplification(
    List<_ProjectedPolygon> polygons,
    double tolerance,
    int zoom,
  ) =>
      List<_ProjectedPolygon>.generate(
        polygons.length,
        (i) {
          final polygon = polygons[i];
          final holes = polygon.holePoints;

          return _ProjectedPolygon._(
            polygon: polygon.polygon,
            points: simplifyPoints(
              polygon.points,
              tolerance / math.pow(2, zoom),
              highestQuality: true,
            ),
            holePoints: holes == null
                ? null
                : List<List<DoublePoint>>.generate(
                    holes.length,
                    (j) => simplifyPoints(
                      holes[j],
                      tolerance / math.pow(2, zoom),
                      highestQuality: true,
                    ),
                    growable: false,
                  ),
          );
        },
        growable: false,
      );
}
