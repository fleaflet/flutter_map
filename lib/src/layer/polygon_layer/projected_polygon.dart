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
          points: projection.projectList(polygon.points),
          holePoints: () {
            final holes = polygon.holePointsList;
            if (holes == null ||
                holes.isEmpty ||
                (polygon.points.isEmpty && !polygon.justHoles) ||
                holes.every((e) => e.isEmpty)) {
              return <List<Offset>>[];
            }

            return List<List<Offset>>.generate(
              holes.length,
              (j) => projection.projectList(
                holes[j],
                referencePoint: polygon.justHoles ? null : polygon.points[0],
              ),
              growable: false,
            );
          }(),
        );
}
