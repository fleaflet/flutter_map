part of 'polyline_layer.dart';

@immutable
class _ProjectedPolyline {
  final Polyline polyline;
  final List<DoublePoint> points;

  const _ProjectedPolyline._({
    required this.polyline,
    required this.points,
  });

  _ProjectedPolyline.fromPolyline(Projection projection, Polyline polyline)
      : this._(
          polyline: polyline,
          points: List<DoublePoint>.generate(
            polyline.points.length,
            (j) {
              final (x, y) = projection.projectXY(polyline.points[j]);
              return DoublePoint(x, y);
            },
            growable: false,
          ),
        );
}
