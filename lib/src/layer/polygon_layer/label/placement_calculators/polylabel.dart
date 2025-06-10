part of 'placement_calculator.dart';

/// {@template fm.polygonLabelPlacementCalculator.polylabel}
/// Places the [Polygon.label] at the point furthest away from the outline,
/// calculated using a Dart implementation of
/// [Mapbox's 'polylabel' algorithm](https://github.com/JaffaKetchup/dart_polylabel2)
///
/// This is more computationally expensive than other calculators but may yield
/// better results.
///
/// The [precision] may be adjusted to change the computational expense and
/// result accuracy. See documentation on [precision] for more information.
/// {@endtemplate}
class PolylabelCalculator implements PolygonLabelPlacementCalculator {
  // Does not need to be `@literal`, as equality is implemented based on state
  const PolylabelCalculator._({
    this.precision = 0.0001,
  });

  /// Threshold for when to stop dividing-and-conquering the polygon in the
  /// hopes of finding a better point with more distance to the polygon's
  /// outline
  ///
  /// A higher number means less precision (less optimal placement), which is
  /// computationally cheaper (requires fewer iterations).
  ///
  /// Specifying a number too small may result in program hangs.
  ///
  /// Specified in geographical space, i.e. degrees. Therefore, as the polygon
  /// gets larger, this should also get larger.
  ///
  /// Defaults to 0.0001.
  final double precision;

  @override
  LatLng call(Polygon polygon) {
    final (point: (:x, :y), distance: _) = dart_polylabel2.polylabel(
      [
        List<dart_polylabel2.Point>.generate(
          polygon.points.length,
          (i) =>
              (x: polygon.points[i].latitude, y: polygon.points[i].longitude),
          growable: false,
        ),
      ],
      precision: precision,
    );
    return LatLng(x, y);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PolylabelCalculator && precision == other.precision);

  @override
  int get hashCode => precision.hashCode;
}
