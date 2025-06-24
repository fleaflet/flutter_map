part of 'placement_calculator.dart';

/// {@template fm.polygonLabelPlacementCalculator.simpleCentroid}
/// Places the [Polygon.label] at the approximate centroid calculated by
/// averaging all the points of the polygon
///
/// This is computationally cheap and gives reasonable results for convex
/// polygons. However, for more complex or convex polygons, results may not be
/// as good (but they should still be acceptable).
///
/// > [!IMPORTANT]
/// > If the polygon may be over the anti-meridan boundary,
/// > [SimpleMultiWorldCentroidCalculator] must be used - other
/// > calculators will produce unexpected results.
/// {@endtemplate}
class SimpleCentroidCalculator implements PolygonLabelPlacementCalculator {
  @literal // Required for equality purposes
  const SimpleCentroidCalculator._();

  @override
  LatLng call(Polygon polygon) => LatLng(
        polygon.points.map((e) => e.latitude).average,
        polygon.points.map((e) => e.longitude).average,
      );
}

/// Similar to [SimpleCentroidCalculator], but supports correct placement of the
/// [Polygon.label] when the polygon lies across the anti-meridian
class SimpleMultiWorldCentroidCalculator
    implements PolygonLabelPlacementCalculator {
  @literal // Required for equality purposes
  const SimpleMultiWorldCentroidCalculator._();

  @override
  LatLng call(Polygon polygon) {
    if (polygon.points.isEmpty) {
      throw ArgumentError('Polygon must contain at least one point');
    }

    const halfWorld = 180;
    int count = 0;
    double sum = 0;
    late double lastLng;
    for (final LatLng point in polygon.points) {
      double lng = point.longitude;
      count++;
      if (count > 1) {
        if (lng - lastLng > halfWorld) {
          lng -= 2 * halfWorld;
        } else if (lng - lastLng < -halfWorld) {
          lng += 2 * halfWorld;
        }
      }
      lastLng = lng;
      sum += lastLng;
    }
    return LatLng(polygon.points.map((e) => e.latitude).average, sum / count);
  }
}
