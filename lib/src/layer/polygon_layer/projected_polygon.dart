part of 'polygon_layer.dart';

@immutable
class _ProjectedPolygon<R extends Object> with HitDetectableElement<R> {
  final Polygon<R> polygon;
  final List<DoublePoint> points;
  final List<List<DoublePoint>> holePoints;

  @override
  R? get hitValue => polygon.hitValue;

  const _ProjectedPolygon._({
    required this.polygon,
    required this.points,
    required this.holePoints,
  });

  _ProjectedPolygon._fromPolygon(Projection projection, Polygon<R> polygon)
      : this._(
          polygon: polygon,
          points: List<DoublePoint>.generate(
            polygon.points.length,
            (j) {
              final (x, y) = projection.projectXY(polygon.points[j]);
              return DoublePoint(x, y);
            },
            growable: false,
          ),
          holePoints: () {
            final holes = polygon.holePointsList;
            if (holes == null ||
                holes.isEmpty ||
                holes.every((e) => e.isEmpty)) {
              return <List<DoublePoint>>[];
            }

            return List<List<DoublePoint>>.generate(
              holes.length,
              (j) {
                final points = holes[j];
                return List<DoublePoint>.generate(
                  points.length,
                  (k) {
                    final (x, y) = projection.projectXY(points[k]);
                    return DoublePoint(x, y);
                  },
                  growable: false,
                );
              },
              growable: false,
            );
          }(),
        );
}
