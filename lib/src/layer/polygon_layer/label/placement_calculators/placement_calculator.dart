import 'package:collection/collection.dart';
import 'package:dart_polylabel2/dart_polylabel2.dart' as dart_polylabel2;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

part 'centroid.dart';
part 'polylabel.dart';
part 'simple_centroid.dart';

/// Calculates the position of a [Polygon.label] within its [Polygon] in
/// geographic (lat/lng) space
///
/// > [!IMPORTANT]
/// > If the polygon may be over the anti-meridan boundary,
/// > [PolygonLabelPlacementCalculator.simpleMultiWorldCentroid] must be used -
/// > other calculators will produce unexpected results.
///
/// ---
///
/// Implementers: if the constructor is zero-argument, and there is no equality
/// implementation, constructors should always be invoked with the `const`
/// keyword, which may be enforced with the [literal] annotation.
@immutable
abstract interface class PolygonLabelPlacementCalculator {
  /// {@macro fm.polygonLabelPlacementCalculator.simpleCentroid}
  @literal
  const factory PolygonLabelPlacementCalculator.simpleCentroid() =
      SimpleCentroidCalculator._;

  /// Similar to [PolygonLabelPlacementCalculator.simpleCentroid], but supports
  /// correct placement of the [Polygon.label] when the polygon lies across the
  /// anti-meridian
  @literal
  const factory PolygonLabelPlacementCalculator.simpleMultiWorldCentroid() =
      SimpleMultiWorldCentroidCalculator._;

  /// {@macro fm.polygonLabelPlacementCalculator.centroid}
  @literal
  const factory PolygonLabelPlacementCalculator.centroid() =
      CentroidCalculator._;

  /// {@macro fm.polygonLabelPlacementCalculator.polylabel}
  const factory PolygonLabelPlacementCalculator.polylabel({double precision}) =
      PolylabelCalculator._;

  /// Given a polygon (and its points), calculate a single position at which
  /// the center of the label should be placed
  ///
  /// [Polygon.points] is not guaranteed to be non-empty. If empty, this may
  /// throw.
  LatLng call(Polygon polygon);
}
