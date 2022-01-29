import 'package:latlong2/latlong.dart';

/// Geographical point with applied zoom level
class CenterZoom {
  /// Coordinates for zoomed point
  final LatLng center;

  /// Zoom value
  final double zoom;
  CenterZoom({required this.center, required this.zoom});
}
