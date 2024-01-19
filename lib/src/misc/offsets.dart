import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

Offset getOffset(MapCamera camera, Offset origin, LatLng point) {
  final crs = camera.crs;
  final zoomScale = crs.scale(camera.zoom);
  final (x, y) = crs.latLngToXY(point, zoomScale);
  return Offset(x - origin.dx, y - origin.dy);
}

List<Offset> getOffsets(MapCamera camera, Offset origin, List<LatLng> points) {
  // Critically create as little garbage as possible. This is called on every frame.
  final crs = camera.crs;
  final zoomScale = crs.scale(camera.zoom);

  final ox = -origin.dx;
  final oy = -origin.dy;
  final len = points.length;

  // Optimization: monomorphize the Epsg3857-case to save the virtual function overhead.
  if (crs is Epsg3857) {
    final Epsg3857 epsg3857 = crs;
    final v = List<Offset>.filled(len, Offset.zero);
    for (int i = 0; i < len; ++i) {
      final (x, y) = epsg3857.latLngToXY(points[i], zoomScale);
      v[i] = Offset(x + ox, y + oy);
    }
    return v;
  }

  final v = List<Offset>.filled(len, Offset.zero);
  for (int i = 0; i < len; ++i) {
    final (x, y) = crs.latLngToXY(points[i], zoomScale);
    v[i] = Offset(x + ox, y + oy);
  }
  return v;
}
