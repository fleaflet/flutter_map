part of 'polyline_layer.dart';

@immutable
class _ProjectedPolyline<R extends Object> with HitDetectableElement<R> {
  final Polyline<R> polyline;
  final List<Offset> points;

  @override
  R? get hitValue => polyline.hitValue;

  const _ProjectedPolyline._({
    required this.polyline,
    required this.points,
  });

  _ProjectedPolyline._fromPolyline(Projection projection, Polyline<R> polyline)
      : this._(
          polyline: polyline,
          points: List<Offset>.generate(
            polyline.points.length,
            (j) {
              final (x, y) = projection.projectXY(polyline.points[j]);
              return Offset(x, y);
            },
            growable: false,
          ),
        );
}
