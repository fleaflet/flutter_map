part of 'placement_calculator.dart';

/// {@template fm.polygonLabelPlacementCalculator.centroid}
/// Places the [Polygon.label] at the centroid calculated using the
/// [signed area formula](https://en.wikipedia.org/wiki/Centroid#Of_a_polygon)
///
/// This a little more computationally expensive than the simple centroid
/// calculator, but yields better results, especially for non-convex polygons.
/// {@endtemplate}
class CentroidCalculator implements PolygonLabelPlacementCalculator {
  @literal // Required for equality purposes
  const CentroidCalculator._();

  @override
  LatLng call(Polygon polygon) {
    final points = polygon.points;

    if (points.isEmpty) {
      throw ArgumentError('Polygon must contain at least one point');
    }

    if (points.length == 1) return points[0];

    double signedArea = 0;
    double centroidX = 0;
    double centroidY = 0;

    // For all vertices except last
    for (int i = 0; i < points.length - 1; i++) {
      final double x0 = points[i].longitude;
      final double y0 = points[i].latitude;
      final double x1 = points[i + 1].longitude;
      final double y1 = points[i + 1].latitude;

      // Calculate signed area contribution of current vertex
      final double a = x0 * y1 - x1 * y0;
      signedArea += a;

      // Accumulate centroid components weighted by signed area
      centroidX += (x0 + x1) * a;
      centroidY += (y0 + y1) * a;
    }

    // Close the polygon by connecting last vertex to first
    final double x0 = points.last.longitude;
    final double y0 = points.last.latitude;
    final double x1 = points.first.longitude;
    final double y1 = points.first.latitude;
    final double a = x0 * y1 - x1 * y0;
    signedArea += a;
    centroidX += (x0 + x1) * a;
    centroidY += (y0 + y1) * a;

    // Complete the signed area calculation
    signedArea *= 0.5;

    // Calculate centroid coordinates
    centroidX /= 6 * signedArea;
    centroidY /= 6 * signedArea;

    // Handle special case of zero area (collinear points)
    if (signedArea == 0) {
      // Default to average of all points
      double sumX = 0;
      double sumY = 0;
      for (final point in points) {
        sumX += point.longitude;
        sumY += point.latitude;
      }
      return LatLng(sumY / points.length, sumX / points.length);
    }

    return LatLng(centroidY, centroidX);
  }
}
