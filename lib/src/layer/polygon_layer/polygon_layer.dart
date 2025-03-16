import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dart_earcut/dart_earcut.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/shared/feature_layer_utils.dart';
import 'package:flutter_map/src/layer/shared/layer_interactivity/internal_hit_detectable.dart';
import 'package:flutter_map/src/layer/shared/layer_projection_simplification/state.dart';
import 'package:flutter_map/src/layer/shared/layer_projection_simplification/widget.dart';
import 'package:flutter_map/src/layer/shared/line_patterns/pixel_hiker.dart';
import 'package:flutter_map/src/misc/offsets.dart';
import 'package:flutter_map/src/misc/point_in_polygon.dart';
import 'package:flutter_map/src/misc/simplify.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:logger/logger.dart';
import 'package:polylabel/polylabel.dart';

part 'label.dart';
part 'painter.dart';
part 'polygon.dart';
part 'projected_polygon.dart';

/// A polygon layer for [FlutterMap].
@immutable
base class PolygonLayer<R extends Object>
    extends ProjectionSimplificationManagementSupportedWidget {
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
  final bool debugAltRenderer;

  /// Whether to cull polygons and polygon sections that are outside of the
  /// viewport
  ///
  /// Defaults to `true`. Disabling is not recommended.
  final bool polygonCulling;

  /// Whether to draw per-polygon labels
  ///
  /// Defaults to `true`.
  final bool polygonLabels;

  /// Whether to draw labels last and thus over all the polygons
  ///
  /// Defaults to `false`.
  final bool drawLabelsLast;

  /// Color to apply to the map where not covered by a polygon
  ///
  /// > [!WARNING]
  /// > On the web, inverted filling may not work as expected in some cases.
  /// > It will not match the behaviour seen on native platforms. Avoid allowing
  /// > polygons to intersect, and avoid using holes within polygons.
  /// > This is due to multiple limitations/bugs within Flutter. See the
  /// > [online documentation](docs.fleaflet.dev/layers/polygon-layer#inverted-filling)
  /// > for more info.
  final Color? invertedFill;

  /// {@macro fm.lhn.layerHitNotifier.usage}
  final LayerHitNotifier<R>? hitNotifier;

  /// Create a new [PolygonLayer] for the [FlutterMap] widget.
  const PolygonLayer({
    super.key,
    required this.polygons,
    this.useAltRendering = false,
    this.debugAltRenderer = false,
    this.polygonCulling = true,
    this.polygonLabels = true,
    this.drawLabelsLast = false,
    this.invertedFill,
    this.hitNotifier,
    super.simplificationTolerance,
  }) : super();

  @override
  State<PolygonLayer<R>> createState() => _PolygonLayerState<R>();
}

class _PolygonLayerState<R extends Object> extends State<PolygonLayer<R>>
    with
        ProjectionSimplificationManagement<_ProjectedPolygon<R>, Polygon<R>,
            PolygonLayer<R>> {
  @override
  void didUpdateWidget(covariant PolygonLayer<R> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (kDebugMode &&
        kIsWeb &&
        oldWidget.invertedFill == null &&
        widget.invertedFill != null) {
      Logger(printer: PrettyPrinter(methodCount: 0)).w(
        '\x1B[1m\x1B[3mflutter_map\x1B[0m\nOn the web, inverted filling may '
        'not work as expected in some cases. It will not match the behaviour\n'
        'seen on native platforms.\nAvoid allowing polygons to intersect, and '
        'avoid using holes within polygons.\nThis is due to multiple '
        'limitations/bugs within Flutter.\nSee '
        'https://docs.fleaflet.dev/layers/polyline-layer#culling for more info.',
      );
    }
  }

  @override
  _ProjectedPolygon<R> projectElement({
    required Projection projection,
    required Polygon<R> element,
  }) =>
      _ProjectedPolygon._fromPolygon(projection, element);

  @override
  _ProjectedPolygon<R> simplifyProjectedElement({
    required _ProjectedPolygon<R> projectedElement,
    required double tolerance,
  }) =>
      _ProjectedPolygon._(
        polygon: projectedElement.polygon,
        points: simplifyPoints(
          points: projectedElement.points,
          tolerance: tolerance,
          highQuality: true,
        ),
        holePoints: List.generate(
          projectedElement.holePoints.length,
          (j) => simplifyPoints(
            points: projectedElement.holePoints[j],
            tolerance: tolerance,
            highQuality: true,
          ),
          growable: false,
        ),
      );

  @override
  List<Polygon<R>> get elements => widget.polygons;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final camera = MapCamera.of(context);

    final culled = !widget.polygonCulling
        ? simplifiedElements.toList()
        : simplifiedElements
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
                      ? points.elementAt(ii ~/ 2).dx
                      : points.elementAt(ii ~/ 2).dy,
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
          invertedFill: widget.invertedFill,
          debugAltRenderer: widget.debugAltRenderer,
          hitNotifier: widget.hitNotifier,
        ),
        size: camera.size,
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
}
