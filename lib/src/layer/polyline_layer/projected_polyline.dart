part of 'polyline_layer.dart';

@immutable
final class _ProjectedPolyline<R extends Object>
    extends ProjectedHittableElement<R> {
  final Polyline<R> polyline;

  @override
  R? get hitValue => polyline.hitValue;

  const _ProjectedPolyline({
    required this.polyline,
    required super.points,
  });

  _ProjectedPolyline.fromPolyline(Projection projection, Polyline<R> polyline)
      : this(
          polyline: polyline,
          points: projection.projectList(polyline.points),
        );
}
