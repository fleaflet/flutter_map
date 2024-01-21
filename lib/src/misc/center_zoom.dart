import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Geographical point with applied zoom level
@immutable
class CenterZoom {
  /// Coordinates for zoomed point
  final LatLng center;

  /// Zoom value
  final double zoom;

  /// Create a new [CenterZoom] object by setting all its values.
  const CenterZoom({required this.center, required this.zoom});

  /// Wither that returns a new [CenterZoom] object with an updated map center.
  CenterZoom withCenter(LatLng center) =>
      CenterZoom(center: center, zoom: zoom);

  /// Wither that returns a new [CenterZoom] object with an updated zoom value.
  CenterZoom withZoom(double zoom) => CenterZoom(center: center, zoom: zoom);

  @override
  int get hashCode => Object.hash(center, zoom);

  @override
  bool operator ==(Object other) =>
      other is CenterZoom && other.center == center && other.zoom == zoom;

  @override
  String toString() => 'CenterZoom(center: $center, zoom: $zoom)';
}
