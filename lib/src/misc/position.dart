import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

// ignore_for_file: public_member_api_docs

@immutable
class MapPosition {
  final LatLng? center;
  final LatLngBounds? bounds;
  final double? zoom;

  /// {@template map_position.has_gesture}
  /// [hasGesture] determines if the change was caused by a user gesture (interaction with the map) if true,
  /// otherwise, if false, the change was not caused by a user gesture, but by a programmatic change
  ///
  /// For example, if the map's position was changed using the map's controller, then [hasGesture] would be false
  /// because the change was not caused by a user gesture, but programmatically.
  /// {@endtemplate}
  final bool hasGesture;

  const MapPosition({
    this.center,
    this.bounds,
    this.zoom,
    this.hasGesture = false,
  });

  @override
  int get hashCode => Object.hash(center, bounds, zoom);

  @override
  bool operator ==(Object other) =>
      other is MapPosition &&
      other.center == center &&
      other.bounds == bounds &&
      other.zoom == zoom;
}
