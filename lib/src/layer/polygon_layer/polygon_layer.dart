import 'dart:math' as math;
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dart_earcut/dart_earcut.dart';
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
part 'projected_polygon.dart';

/// A polygon layer for [FlutterMap].
@immutable
class PolygonLayer extends StatefulWidget {
  /// [Polygon]s to draw
  final List<Polygon> polygons;

  /// Whether to use more performant methods to draw polygons
  ///
  /// When enabled, this internally:
  /// * triangulates each polygon using the
  /// ['dart_earcut' package](https://github.com/JaffaKetchup/dart_earcut)
  /// * then uses [`drawVertices`](https://www.youtube.com/watch?v=pD38Yyz7N2E)
  /// to draw the triangles to the underlying canvas
  ///
  /// In some cases, such as when input polygons are complex/self-intersecting,
  /// the triangulation step can yield poor results, which will appear as
  /// malformed polygons on the canvas. Disable this argument to use standard
  /// canvas drawing methods which don't suffer this issue.
  ///
  /// Defaults to `true`. Will respect feature level
  /// [Polygon.performantRendering] when this is `true`.
  final bool performantRendering;

  /// Whether to cull polygons and polygon sections that are outside of the
  /// viewport
  ///
  /// Defaults to `true`. Disabling is not recommended.
  final bool polygonCulling;

  /// Distance between two neighboring polygon points, in logical pixels scaled
  /// to floored zoom
  ///
  /// Increasing this value results in points further apart being collapsed and
  /// thus more simplified polygons. Higher values improve performance at the
  /// cost of visual fidelity and vice versa.
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
    this.performantRendering = true,
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
  final _cachedSimplifiedPolygons = <int, List<_ProjectedPolygon>>{};

  @override
  void didUpdateWidget(PolygonLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reuse cache
    if (widget.simplificationTolerance != 0 &&
        oldWidget.simplificationTolerance == widget.simplificationTolerance &&
        listEquals(oldWidget.polygons, widget.polygons)) return;

    _cachedSimplifiedPolygons.clear();
    _cachedProjectedPolygons = null;
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    final projected = _cachedProjectedPolygons ??= List.generate(
      widget.polygons.length,
      (i) => _ProjectedPolygon._fromPolygon(
        camera.crs.projection,
        widget.polygons[i],
      ),
      growable: false,
    );

    final simplified = widget.simplificationTolerance <= 0
        ? projected
        : _cachedSimplifiedPolygons[camera.zoom.floor()] ??=
            _computeZoomLevelSimplification(
            polygons: projected,
            pixelTolerance: widget.simplificationTolerance,
            camera: camera,
          );

    final culled = !widget.polygonCulling
        ? simplified
        : simplified
            .where(
              (p) => p.polygon.boundingBox.isOverlapping(camera.visibleBounds),
            )
            .toList();

    final triangles = !widget.performantRendering
        ? null
        : List.generate(
            culled.length,
            (i) {
              final culledPolygon = culled[i];
              if (!culledPolygon.polygon.performantRendering) return null;

              return Earcut.triangulateRaw(
                (culledPolygon.holePoints.isNotEmpty
                        ? culledPolygon.points.followedBy(
                            culledPolygon.holePoints.expand((e) => e))
                        : culledPolygon.points)
                    .map((e) => [e.x, e.y])
                    .expand((e) => e)
                    .toList(growable: false),
                // Not sure how just this works but it seems to :D
                holeIndices: culledPolygon.holePoints.isNotEmpty
                    ? [culledPolygon.points.length]
                    : null,
              );
            },
            growable: false,
          );

    return MobileLayerTransformer(
      child: CustomPaint(
        painter: _PolygonPainter(
          polygons: culled,
          triangles: triangles,
          camera: camera,
          polygonLabels: widget.polygonLabels,
          drawLabelsLast: widget.drawLabelsLast,
        ),
        size: Size(camera.size.x, camera.size.y),
      ),
    );
  }

  static List<_ProjectedPolygon> _computeZoomLevelSimplification({
    required List<_ProjectedPolygon> polygons,
    required double pixelTolerance,
    required MapCamera camera,
  }) {
    final tolerance = getEffectiveSimplificationTolerance(
      crs: camera.crs,
      zoom: camera.zoom.floor(),
      pixelTolerance: pixelTolerance,
    );

    return List<_ProjectedPolygon>.generate(
      polygons.length,
      (i) {
        final polygon = polygons[i];
        final holes = polygon.holePoints;

        return _ProjectedPolygon._(
          polygon: polygon.polygon,
          points: simplifyPoints(
            points: polygon.points,
            tolerance: tolerance,
            highQuality: true,
          ),
          holePoints: holes.isEmpty
              ? []
              : List.generate(
                  holes.length,
                  (j) => simplifyPoints(
                    points: holes[j],
                    tolerance: tolerance,
                    highQuality: true,
                  ),
                  growable: false,
                ),
        );
      },
      growable: false,
    );
  }
}
