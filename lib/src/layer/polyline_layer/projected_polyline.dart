part of 'polyline_layer.dart';

@immutable
class _ProjectedPolyline<R extends Object> with HitDetectableElement<R> {
  final Polyline<R> polyline;
  final List<DoublePoint> points;

  @override
  R? get hitValue => polyline.hitValue;

  const _ProjectedPolyline._({
    required this.polyline,
    required this.points,
  });

  _ProjectedPolyline._fromPolyline(Projection projection, Polyline<R> polyline)
      : this._(
          polyline: polyline,
          points: projection.projectList(polyline.points),
        );
}
