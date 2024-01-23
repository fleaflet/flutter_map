part of 'polygon_layer.dart';

@immutable
class _ProjectedPolygon {
  final Polygon polygon;
  final List<DoublePoint> points;
  final List<List<DoublePoint>>? holePoints;

  const _ProjectedPolygon._({
    required this.polygon,
    required this.points,
    this.holePoints,
  });

  _ProjectedPolygon._fromPolygon(Projection projection, Polygon polygon)
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
            if (holes == null) return null;

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
