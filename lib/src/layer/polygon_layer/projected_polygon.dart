part of 'polygon_layer.dart';

@immutable
class _ProjectedPolygon<R extends Object> with HitDetectableElement<R> {
  final Polygon<R> polygon;
  final List<Offset> points;
  final List<List<Offset>> holePoints;

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
          points: List<Offset>.generate(
            polygon.points.length,
            (j) {
              final (x, y) = projection.projectXY(polygon.points[j]);
              return Offset(x, y);
            },
            growable: false,
          ),
          holePoints: () {
            final holes = polygon.holePointsList;
            if (holes == null ||
                holes.isEmpty ||
                holes.every((e) => e.isEmpty)) {
              return <List<Offset>>[];
            }

            return List<List<Offset>>.generate(
              holes.length,
              (j) {
                final points = holes[j];
                return List<Offset>.generate(
                  points.length,
                  (k) {
                    final (x, y) = projection.projectXY(points[k]);
                    return Offset(x, y);
                  },
                  growable: false,
                );
              },
              growable: false,
            );
          }(),
        );
}
