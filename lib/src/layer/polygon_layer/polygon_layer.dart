import 'dart:math' as math;
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dart_earcut/dart_earcut.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/shared/layer_interactivity/internal_hit_detectable.dart';
import 'package:flutter_map/src/layer/shared/line_patterns/pixel_hiker.dart';
import 'package:flutter_map/src/misc/offsets.dart';
import 'package:flutter_map/src/misc/point_in_polygon.dart';
import 'package:flutter_map/src/misc/simplify.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:polylabel/polylabel.dart';

part 'label.dart';
part 'painter.dart';
part 'polygon.dart';
part 'projected_polygon.dart';

/// A polygon layer for [FlutterMap].
@immutable
class PolygonLayer<R extends Object> extends StatefulWidget {
  /// [Polygon]s to draw
  final List<Polygon<R>> polygons;

  /// Whether to use an alternative rendering pathway to draw polygons onto the
  /// underlying `Canvas`, which can be more performant in *some* circumstances
  ///
  /// This will not always improve performance, and there are other important
  /// considerations before enabling it. It is intended for use when prior
  /// profiling indicates more performance is required after other methods are
  /// already in use. For example, it may worsen performance when there are a
  /// huge number of polygons to triangulate - and so this is best used in
  /// conjunction with simplification, not as a replacement.
  ///
  /// For more information about usage and pitfalls, see the
  /// [online documentation](https://docs.fleaflet.dev/layers/polygon-layer#performant-rendering-with-drawvertices-internal-disabled).
  ///
  /// Defaults to `false`. Ensure you have read and understood the documentation
  /// above before enabling.
  final bool useAltRendering;

  /// Whether to overlay a debugging tool when [useAltRendering] is enabled to
  /// display triangulation results
  ///
  /// Ignored when not in debug mode.
  final bool debugAltRenderer;

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

  /// {@macro fm.lhn.layerHitNotifier.usage}
  final LayerHitNotifier<R>? hitNotifier;

  /// Create a new [PolygonLayer] for the [FlutterMap] widget.
  const PolygonLayer({
    super.key,
    required this.polygons,
    this.useAltRendering = false,
    bool debugAltRenderer = false,
    this.polygonCulling = true,
    this.simplificationTolerance = 0.5,
    this.polygonLabels = true,
    this.drawLabelsLast = false,
    this.hitNotifier,
  })  : assert(
          simplificationTolerance >= 0,
          'simplificationTolerance cannot be negative: $simplificationTolerance',
        ),
        debugAltRenderer = kDebugMode && debugAltRenderer;

  @override
  State<PolygonLayer<R>> createState() => _PolygonLayerState<R>();
}

class _PolygonLayerState<R extends Object> extends State<PolygonLayer<R>> {
  List<_ProjectedPolygon<R>>? _cachedProjectedPolygons;
  final _cachedSimplifiedPolygons = <int, List<_ProjectedPolygon<R>>>{};

  double? _devicePixelRatio;

  @override
  void didUpdateWidget(PolygonLayer<R> oldWidget) {
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

    late final List<_ProjectedPolygon<R>> simplified;
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

    final triangles = !widget.useAltRendering
        ? null
        : List.generate(
            culled.length,
            (i) {
              final culledPolygon = culled[i];

              final points = culledPolygon.holePoints.isEmpty
                  ? culledPolygon.points
                  : culledPolygon.points
                      .followedBy(culledPolygon.holePoints.expand((e) => e));

              return Earcut.triangulateRaw(
                List.generate(
                  points.length * 2,
                  (ii) => ii.isEven
                      ? points.elementAt(ii ~/ 2).x
                      : points.elementAt(ii ~/ 2).y,
                  growable: false,
                ),
                holeIndices: culledPolygon.holePoints.isEmpty
                    ? null
                    : _generateHolesIndices(culledPolygon)
                        .toList(growable: false),
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
          debugAltRenderer: widget.debugAltRenderer,
          hitNotifier: widget.hitNotifier,
        ),
        size: Size(camera.size.x, camera.size.y),
      ),
    );
  }

  Iterable<int> _generateHolesIndices(_ProjectedPolygon<R> polygon) sync* {
    var prevValue = polygon.points.length;
    yield prevValue;

    for (int i = 0; i < polygon.holePoints.length - 1; i++) {
      yield prevValue += polygon.holePoints[i].length;
    }
  }

  List<_ProjectedPolygon<R>> _computeZoomLevelSimplification({
    required MapCamera camera,
    required List<_ProjectedPolygon<R>> polygons,
    required double pixelTolerance,
    required double devicePixelRatio,
  }) {
    final tolerance = getEffectiveSimplificationTolerance(
      crs: camera.crs,
      zoom: camera.zoom.floor(),
      pixelTolerance: pixelTolerance,
      devicePixelRatio: devicePixelRatio,
    );

    return List<_ProjectedPolygon<R>>.generate(
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
          holePoints: List.generate(
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
