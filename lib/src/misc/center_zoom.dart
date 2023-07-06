import 'package:latlong2/latlong.dart';

/// Geographical point with applied zoom level
class CenterZoom {
  /// Coordinates for zoomed point
  final LatLng center;

  /// Zoom value
  final double zoom;

  CenterZoom({required this.center, required this.zoom});

  CenterZoom withCenter(LatLng center) =>
      CenterZoom(center: center, zoom: zoom);

  CenterZoom withZoom(double zoom) => CenterZoom(center: center, zoom: zoom);

  @override
  int get hashCode => Object.hash(center, zoom);

  @override
  bool operator ==(Object other) =>
      other is CenterZoom && other.center == center && other.zoom == zoom;

  @override
  String toString() => 'CenterZoom(center: $center, zoom: $zoom)';
}
