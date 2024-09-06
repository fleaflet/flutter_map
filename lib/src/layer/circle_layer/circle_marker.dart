part of 'circle_layer.dart';

/// Immutable marker options for [CircleMarker]. Circle markers are a more
/// simple and performant way to draw markers as the regular [Marker]
@immutable
class CircleMarker<R extends Object> with HitDetectableElement<R> {
  /// An optional [Key] for the [CircleMarker].
  /// This key is not used internally.
  final Key? key;

  /// The center coordinates of the circle
  final LatLng point;

  /// The radius of the circle
  final double radius;

  /// The color of the circle area.
  final Color color;

  /// The stroke width for the circle border. Defaults to 0 (no border)
  final double borderStrokeWidth;

  /// The color of the circle border line. Needs [borderStrokeWidth] to be > 0
  /// to be visible.
  final Color borderColor;

  /// Set to true if the radius should use the unit meters.
  final bool useRadiusInMeter;

  @override
  final R? hitValue;

  /// Constructor to create a new [CircleMarker] object
  const CircleMarker({
    required this.point,
    required this.radius,
    this.key,
    this.useRadiusInMeter = false,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.hitValue,
  });
}
