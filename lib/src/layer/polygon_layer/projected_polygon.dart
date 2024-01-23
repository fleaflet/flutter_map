part of 'polygon_layer.dart';

class _ProjectedPolygon {
  final Polygon polygon;

  // Mutable to reduce GC stress from repetitive allocation
  List<DoublePoint> points;
  List<List<DoublePoint>>? holePoints;

  _ProjectedPolygon._fromPolygon(Projection projection, this.polygon)
      : points = List<DoublePoint>.generate(
          polygon.points.length,
          (j) {
            final (x, y) = projection.projectXY(polygon.points[j]);
            return DoublePoint(x, y);
          },
          growable: false,
        ),
        holePoints = (() {
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
        }());
}
