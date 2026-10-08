part of 'polyline_layer.dart';

@immutable
class _ProjectedPolyline<R extends Object> with HitDetectableElement<R> {
  final Polyline<R> polyline;
  final List<Offset> points;

  /// Bounding box of [points], in projected space (cached)
  ///
  /// Computed lazily: culled fragments never use it.
  late final Rect boundingBox = RectExtension.containing(points);

  @override
  R? get hitValue => polyline.hitValue;

  _ProjectedPolyline._({
    required this.polyline,
    required this.points,
  });

  _ProjectedPolyline._fromPolyline(
    Projection projection,
    Polyline<R> polyline,
    bool drawInSingleWorld,
  ) : this._(
          polyline: polyline,
          points: projection.projectList(
            polyline.points,
            projectToSingleWorld: drawInSingleWorld,
          ),
        );
}
