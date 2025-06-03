import 'package:flutter_map/flutter_map.dart';

/// Defines the algorithm used to calculate the position of the [Polygon] label.
///
/// > [!IMPORTANT]
/// > If polygons may be over the anti-meridan boundary,
/// > [PolygonLabelPlacementCalculator.simpleMultiWorldCentroid] must be used -
/// > other calculators will produce unexpected results.
@Deprecated(
  'Use `Polygon.labelPlacementCalculator` with the equivalent calculator '
  'instead. '
  'This enables more flexibility and extensibility. '
  'This was deprecated after v8.2.0, and will be removed in a future version.',
)
enum PolygonLabelPlacement {
  /// Alias for [PolygonLabelPlacementCalculator.centroid]
  ///
  /// The new [PolygonLabelPlacementCalculator.centroid] algorithm has differing
  /// behaviour than the old one. To remain using the existing behaviour, use
  /// [PolygonLabelPlacementCalculator.simpleCentroid].
  @Deprecated(
    'Use `Polygon.labelPlacementCalculator` with '
    '`const PolygonLabelPlacementCalculator.simpleCentroid()` or `.centroid()` '
    'instead. '
    'This enables more flexibility and extensibility. '
    'This was deprecated after v8.2.0, and will be removed in a future version.',
  )
  centroid,

  /// Alias for [PolygonLabelPlacementCalculator.simpleMultiWorldCentroid]
  @Deprecated(
    'Use `Polygon.labelPlacementCalculator` with '
    '`const PolygonLabelPlacementCalculator.simpleMultiWorldCentroid()` '
    'instead. '
    'This enables more flexibility and extensibility. '
    'This was deprecated after v8.2.0, and will be removed in a future version.',
  )
  centroidWithMultiWorld,

  /// Alias for [PolygonLabelPlacementCalculator.polylabel]
  @Deprecated(
    'Use `Polygon.labelPlacementCalculator` with '
    '`const PolygonLabelPlacementCalculator.polylabel()` instead. '
    'This enables more flexibility and extensibility. '
    'This was deprecated after v8.2.0, and will be removed in a future version.',
  )
  polylabel,
}
