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
  /// [hasGesture] determines if the change was caused by a user gesture (interaction with the map) or not.
  ///
  /// For example, if the user panned out the map, then [hasGesture] would be true because the change was
  /// caused by a user gesture. On the other hand, if the map's position was changed using the map's
  /// controller, then [hasGesture] would be false because the change was not caused by a user gesture,
  /// but programmatically.
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

/// Callback that gets called when the map's position changes.
///
/// {@macro map_position.has_gesture}
typedef PositionCallback = void Function(MapPosition position, bool hasGesture);
