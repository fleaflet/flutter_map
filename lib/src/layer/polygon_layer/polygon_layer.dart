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

  /// {@template fm.PolygonLayer.performantRendering}
  /// Whether to use an alternative, specialised, rendering pathway to draw
  /// polygons, which can be more performant in some circumstances
  ///
  /// This will not always improve performance, and there are other important
  /// considerations before enabling it. It is intended for use when prior
  /// profiling indicates more performance is required after other methods are
  /// already in use.
  ///
  /// For more information about usage (and the rendering pathway), see the
  /// [online documentation](https://docs.fleaflet.dev/layers/polygon-layer#performant-rendering-drawvertices).
  /// {@endtemplate}
  ///
  /// Value meanings (defaults to `false`):
  ///
  /// - `true` : enabled, but respect individual feature-level overrides
  /// - `false`: disabled, ignore feature-level overrides
  /// - (no option is provided to disable by default but respect feature-level
  /// overrides, as this will likely not be useful for this option's intended
  /// purpose)
  ///
  /// Also see [Polygon.performantRendering].
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
    this.performantRendering = false,
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

  double? _devicePixelRatio;

  @override
  void didUpdateWidget(PolygonLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listEquals(oldWidget.polygons, widget.polygons)) {
      // If the polylines have changed, then both the projections and the
      // projection-dependendent simplifications must be invalidated
      _cachedProjectedPolygons = null;
      _cachedSimplifiedPolygons.clear();
    } else if (oldWidget.simplificationTolerance !=
        widget.simplificationTolerance) {
      // If only the simplification tolerance has changed, this does not affect
      // the projections (as that is done before simplification), so only
      // invalidate the simplifications
      _cachedSimplifiedPolygons.clear();
    }
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

    late final List<_ProjectedPolygon> simplified;
    if (widget.simplificationTolerance == 0) {
      simplified = projected;
    } else {
      // If the DPR has changed, invalidate the simplification cache
      final newDPR = MediaQuery.devicePixelRatioOf(context);
      if (newDPR != _devicePixelRatio) {
        _devicePixelRatio = newDPR;
        _cachedSimplifiedPolygons.clear();
      }

      simplified = _cachedSimplifiedPolygons[camera.zoom.floor()] ??=
          _computeZoomLevelSimplification(
        camera: camera,
        polygons: projected,
        pixelTolerance: widget.simplificationTolerance,
        devicePixelRatio: newDPR,
      );
    }

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

              final points = culledPolygon.holePoints.isEmpty
                  ? culledPolygon.points
                  : culledPolygon.points
                      .followedBy(culledPolygon.holePoints.expand((e) => e));

              return Earcut.triangulateRaw(
                List.generate(
                  points.length * 2,
                  (ii) => ii % 2 == 0
                      ? points.elementAt(ii ~/ 2).x
                      : points.elementAt(ii ~/ 2).y,
                  growable: false,
                ),
                // Not sure how just this works but it seems to :D
                holeIndices: culledPolygon.holePoints.isEmpty
                    ? null
                    : [culledPolygon.points.length],
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
    required MapCamera camera,
    required List<_ProjectedPolygon> polygons,
    required double pixelTolerance,
    required double devicePixelRatio,
  }) {
    final tolerance = getEffectiveSimplificationTolerance(
      crs: camera.crs,
      zoom: camera.zoom.floor(),
      pixelTolerance: pixelTolerance,
      devicePixelRatio: devicePixelRatio,
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
