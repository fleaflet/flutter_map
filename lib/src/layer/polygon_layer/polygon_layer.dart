import 'dart:collection';
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
    this.polygonCulling = true,
    this.simplificationTolerance = 0.5,
    this.polygonLabels = true,
    this.drawLabelsLast = false,
    this.hitNotifier,
  }) : assert(
          simplificationTolerance >= 0,
          'simplificationTolerance cannot be negative: $simplificationTolerance',
        );

  @override
  State<PolygonLayer<R>> createState() => _PolygonLayerState<R>();
}

class _PolygonLayerState<R extends Object> extends State<PolygonLayer<R>> {
  final _cachedProjectedPolygons = SplayTreeMap<int, _ProjectedPolygon<R>>();
  final _cachedSimplifiedPolygons =
      <int, SplayTreeMap<int, _ProjectedPolygon<R>>>{};

  double? _devicePixelRatio;

  @override
  void didUpdateWidget(PolygonLayer<R> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final camera = MapCamera.of(context);

    // If the simplification tolerance has changed, then clear all
    // simplifications to allow `build` to re-simplify.
    final hasSimplficationToleranceChanged =
        oldWidget.simplificationTolerance != widget.simplificationTolerance;
    if (hasSimplficationToleranceChanged) _cachedSimplifiedPolygons.clear();

    // We specifically only use basic equality here, and not deep, since deep
    // will always be equal.
    if (oldWidget.polygons == widget.polygons) return;

    // Loop through all polygons in the new widget
    // If not in the projection cache, then re-project. Also, do the same for
    // the simplification cache, across all zoom levels for each polygon.
    // Then, remove all polygons no longer in the new widget from each cache.
    //
    // This is an O(n^3) operation, assuming n is the number of polygons
    // (assuming they are all similar, otherwise exact runtime will depend on
    // existing cache lengths, etc.). However, compared to previous versions, it
    // takes approximately the same duration, as it relieves the work from the
    // `build` method.
    for (final polygon in widget.polygons) {
      final existingProjection = _cachedProjectedPolygons[polygon.hashCode];

      if (existingProjection == null) {
        _cachedProjectedPolygons[polygon.hashCode] =
            _ProjectedPolygon._fromPolygon(camera.crs.projection, polygon);

        if (hasSimplficationToleranceChanged) continue;

        for (final MapEntry(key: zoomLvl, value: simplifiedPolygons)
            in _cachedSimplifiedPolygons.entries) {
          final simplificationTolerance = getEffectiveSimplificationTolerance(
            crs: camera.crs,
            zoom: zoomLvl,
            // When the tolerance changes, this method handles resetting and filling
            pixelTolerance: widget.simplificationTolerance,
            // When the DPR changes, the `build` method handles resetting and filling
            devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          );

          final existingSimplification = simplifiedPolygons[polygon.hashCode];

          if (existingSimplification == null) {
            _cachedSimplifiedPolygons[zoomLvl]![polygon.hashCode] =
                _simplifyPolygon(
              projectedPolygon: _cachedProjectedPolygons[polygon.hashCode]!,
              tolerance: simplificationTolerance,
            );
          }
        }
      }
    }

    _cachedProjectedPolygons.removeWhere(
        (k, v) => !widget.polygons.map((p) => p.hashCode).contains(k));

    for (final s in _cachedSimplifiedPolygons.values) {
      s.removeWhere(
          (k, v) => !widget.polygons.map((p) => p.hashCode).contains(k));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Performed once only, at load - projects all initial polygons
    if (_cachedProjectedPolygons.isEmpty) {
      final camera = MapCamera.of(context);

      for (final polygon in widget.polygons) {
        _cachedProjectedPolygons[polygon.hashCode] =
            _ProjectedPolygon._fromPolygon(
          camera.crs.projection,
          polygon,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    // The `build` method handles initial simplification, re-simplification only
    // when the DPR has changed, and re-simplification implicitly when the
    // tolerance is changed (and the cache is emptied by `didUpdateWidget`.
    late final Iterable<_ProjectedPolygon<R>> simplified;
    if (widget.simplificationTolerance == 0) {
      simplified = _cachedProjectedPolygons.values;
    } else {
      // If the DPR has changed, invalidate the simplification cache
      final newDPR = MediaQuery.devicePixelRatioOf(context);
      if (newDPR != _devicePixelRatio) {
        _devicePixelRatio = newDPR;
        _cachedSimplifiedPolygons.clear();
      }

      simplified = (_cachedSimplifiedPolygons[camera.zoom.floor()] ??=
              SplayTreeMap.fromIterables(
        _cachedProjectedPolygons.keys,
        _simplifyPolygons(
          camera: camera,
          projectedPolygons: _cachedProjectedPolygons.values,
          pixelTolerance: widget.simplificationTolerance,
          devicePixelRatio: newDPR,
        ),
      ))
          .values;
    }

    final culled = !widget.polygonCulling
        ? simplified.toList()
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
          hitNotifier: widget.hitNotifier,
        ),
        size: Size(camera.size.x, camera.size.y),
      ),
    );
  }

  Iterable<_ProjectedPolygon<R>> _simplifyPolygons({
    required Iterable<_ProjectedPolygon<R>> projectedPolygons,
    required MapCamera camera,
    required double pixelTolerance,
    required double devicePixelRatio,
  }) sync* {
    final tolerance = getEffectiveSimplificationTolerance(
      crs: camera.crs,
      zoom: camera.zoom.floor(),
      pixelTolerance: pixelTolerance,
      devicePixelRatio: devicePixelRatio,
    );

    for (final projectedPolygon in projectedPolygons) {
      yield _simplifyPolygon(
        tolerance: tolerance,
        projectedPolygon: projectedPolygon,
      );
    }
  }

  _ProjectedPolygon<R> _simplifyPolygon({
    required _ProjectedPolygon<R> projectedPolygon,
    required double tolerance,
  }) {
    return _ProjectedPolygon._(
      polygon: projectedPolygon.polygon,
      points: simplifyPoints(
        points: projectedPolygon.points,
        tolerance: tolerance,
        highQuality: true,
      ),
      holePoints: List.generate(
        projectedPolygon.holePoints.length,
        (j) => simplifyPoints(
          points: projectedPolygon.holePoints[j],
          tolerance: tolerance,
          highQuality: true,
        ),
        growable: false,
      ),
    );
  }
}
