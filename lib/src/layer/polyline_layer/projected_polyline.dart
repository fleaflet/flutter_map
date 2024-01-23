part of 'polyline_layer.dart';

class _ProjectedPolyline<R extends Object> {
  final Polyline<R> polyline;

  // Mutable to reduce GC stress from repetitive allocation
  List<DoublePoint> points;

  _ProjectedPolyline._fromPolyline(Projection projection, this.polyline)
      : points = List<DoublePoint>.generate(
          polyline.points.length,
          (j) {
            final (x, y) = projection.projectXY(polyline.points[j]);
            return DoublePoint(x, y);
          },
          growable: false,
        );
}
