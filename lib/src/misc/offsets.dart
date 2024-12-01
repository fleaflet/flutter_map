import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/geo/crs.dart';
import 'package:flutter_map/src/misc/simplify.dart';
import 'package:latlong2/latlong.dart';

/// Calculate the [Offset] for the [LatLng] point.
Offset getOffset(MapCamera camera, Offset origin, LatLng point) {
  final crs = camera.crs;
  final zoomScale = crs.scale(camera.zoom);
  final (x, y) = crs.latLngToXY(point, zoomScale);
  return Offset(x - origin.dx, y - origin.dy);
}

/// Calculate the [Offset]s for the list of [LatLng] points.
List<Offset> getOffsets(MapCamera camera, Offset origin, List<LatLng> points) {
  // Critically create as little garbage as possible. This is called on every frame.
  final crs = camera.crs;
  final zoomScale = crs.scale(camera.zoom);

  final ox = -origin.dx;
  final oy = -origin.dy;
  final len = points.length;

  // Optimization: monomorphize the Epsg3857-case to avoid the virtual function overhead.
  if (crs case final Epsg3857 epsg3857) {
    final v = List<Offset>.filled(len, Offset.zero, growable: true);
    for (int i = 0; i < len; ++i) {
      final (x, y) = epsg3857.latLngToXY(points[i], zoomScale);
      v[i] = Offset(x + ox, y + oy);
    }
    return v;
  }

  final v = List<Offset>.filled(len, Offset.zero, growable: true);
  for (int i = 0; i < len; ++i) {
    final (x, y) = crs.latLngToXY(points[i], zoomScale);
    v[i] = Offset(x + ox, y + oy);
  }
  return v;
}

/// Suitable for both lines, filled polygons, and holed polygons
List<Offset> getOffsetsXY({
  required MapCamera camera,
  required Offset origin,
  required List<DoublePoint> points,
  List<List<DoublePoint>>? holePoints,
}) {
  // Critically create as little garbage as possible. This is called on every frame.
  final crs = camera.crs;
  final zoomScale = crs.scale(camera.zoom);

  final realPoints = holePoints == null || holePoints.isEmpty
      ? points
      : points.followedBy(holePoints.expand((e) => e));

  final ox = -origin.dx;
  final oy = -origin.dy;
  final len = realPoints.length;

  /// Returns additional world width in order to have visible points.
  double getAddedWorldWidth() {
    final worldWidth = crs.projection.getWorldWidth();
    final List<double> addedWidths = [
      0,
      worldWidth,
      -worldWidth,
    ];
    final halfScreenWidth = camera.size.x / 2;
    final p = realPoints.elementAt(0);
    late double result;
    late double bestX;
    for (int i = 0; i < addedWidths.length; i++) {
      final addedWidth = addedWidths[i];
      final (x, _) = crs.transform(p.x + addedWidth, p.y, zoomScale);
      if (i == 0) {
        result = addedWidth;
        bestX = x;
        continue;
      }
      if ((bestX + ox - halfScreenWidth).abs() >
          (x + ox - halfScreenWidth).abs()) {
        result = addedWidth;
        bestX = x;
      }
    }
    return result;
  }

  final double addedWorldWidth = getAddedWorldWidth();

  // Optimization: monomorphize the CrsWithStaticTransformation-case to avoid
  // the virtual function overhead.
  if (crs case final CrsWithStaticTransformation crs) {
    final v = List<Offset>.filled(len, Offset.zero, growable: true);
    for (int i = 0; i < len; ++i) {
      final p = realPoints.elementAt(i);
      final (x, y) = crs.transform(p.x + addedWorldWidth, p.y, zoomScale);
      v[i] = Offset(x + ox, y + oy);
    }
    return v;
  }

  final v = List<Offset>.filled(len, Offset.zero, growable: true);
  for (int i = 0; i < len; ++i) {
    final p = realPoints.elementAt(i);
    final (x, y) = crs.transform(p.x + addedWorldWidth, p.y, zoomScale);
    v[i] = Offset(x + ox, y + oy);
  }
  return v;
}
