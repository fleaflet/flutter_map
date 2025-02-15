part of 'polygon_layer.dart';

@immutable
final class _ProjectedPolygon<R extends Object>
    extends ProjectedHittableElement<R> {
  final Polygon<R> polygon;
  final List<List<Offset>> holePoints;

  @override
  R? get hitValue => polygon.hitValue;

  const _ProjectedPolygon({
    required this.polygon,
    required super.points,
    required this.holePoints,
  });

  _ProjectedPolygon.fromPolygon(Projection projection, Polygon<R> polygon)
      : this(
          polygon: polygon,
          points: projection.projectList(polygon.points),
          holePoints: () {
            final holes = polygon.holePointsList;
            if (holes == null ||
                holes.isEmpty ||
                polygon.points.isEmpty ||
                holes.every((e) => e.isEmpty)) {
              return <List<Offset>>[];
            }

            return List<List<Offset>>.generate(
              holes.length,
              (j) => projection.projectList(
                holes[j],
                referencePoint: polygon.points[0],
              ),
              growable: false,
            );
          }(),
        );
}
