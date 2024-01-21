import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

// ignore_for_file: public_member_api_docs

@immutable
class MapPosition {
  final LatLng? center;
  final LatLngBounds? bounds;
  final double? zoom;
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

typedef PositionCallback = void Function(MapPosition position, bool hasGesture);
