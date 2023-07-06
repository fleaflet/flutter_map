import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:latlong2/latlong.dart';

class MapPosition {
  final LatLng? center;
  final LatLngBounds? bounds;
  final double? zoom;
  final bool hasGesture;

  MapPosition({this.center, this.bounds, this.zoom, this.hasGesture = false});

  @override
  int get hashCode => center.hashCode + bounds.hashCode + zoom.hashCode;

  @override
  bool operator ==(Object other) =>
      other is MapPosition &&
      other.center == center &&
      other.bounds == bounds &&
      other.zoom == zoom;
}

typedef PositionCallback = void Function(MapPosition position, bool hasGesture);
