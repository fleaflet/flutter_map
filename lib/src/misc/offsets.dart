import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/geo/crs.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

@internal
class OffsetHelper {
  OffsetHelper({
    required this.camera,
  })  : _replicatesWorldLongitude = camera.crs.replicatesWorldLongitude,
        _origin = camera.pixelOrigin;

  final MapCamera camera;

  final Offset _origin;
  final bool _replicatesWorldLongitude;

  /// Calculate the [Offset] for the [LatLng] point.
  Offset getOffset(
    LatLng point, {
    double shift = 0,
  }) {
    final crs = camera.crs;
    final zoomScale = crs.scale(camera.zoom);
    final (x, y) = crs.latLngToXY(point, zoomScale);
    return Offset(x - _origin.dx + shift, y - _origin.dy);
  }

  // TODO not sure if still relevant
  /// Calculate the [Offset]s for the list of [LatLng] points.
  List<Offset> getOffsets(List<LatLng> points) {
    // Critically create as little garbage as possible. This is called on every frame.
    final crs = camera.crs;
    final zoomScale = crs.scale(camera.zoom);

    final ox = -_origin.dx;
    final oy = -_origin.dy;
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

  /// Suitable for polylines, filled polygons, and holed polygons
  (List<Offset>, double) getOffsetsXY({
    required List<Offset> points,
    List<List<Offset>>? holePoints,
    double shift = 0,
    // most of the time will be null, except for polygon holes
    double? forcedAddedWorldWidth,
  }) {
    // Critically create as little garbage as possible. This is called on every frame.
    final crs = camera.crs;
    final zoomScale = crs.scale(camera.zoom);

    final realPoints = holePoints == null || holePoints.isEmpty
        ? points
        : points.followedBy(holePoints.expand((e) => e));

    final ox = -_origin.dx;
    final oy = -_origin.dy;
    final len = realPoints.length;

    /// Returns additional world width in order to have visible points.
    double getAddedWorldWidth() {
      if (!_replicatesWorldLongitude) {
        return 0;
      }
      if (forcedAddedWorldWidth != null) {
        return forcedAddedWorldWidth;
      }
      final worldWidth = crs.projection.getWorldWidth();
      final List<double> addedWidths = [
        0,
        worldWidth,
        -worldWidth,
      ];
      final halfScreenWidth = camera.size.width / 2;
      final p = realPoints.elementAt(0);
      late double result;
      late double bestX;
      for (int i = 0; i < addedWidths.length; i++) {
        final addedWidth = addedWidths[i];
        final (x, _) = crs.transform(p.dx + addedWidth, p.dy, zoomScale);
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

    final addedWorldWidth = getAddedWorldWidth();

    // Optimization: monomorphize the CrsWithStaticTransformation-case to avoid
    // the virtual function overhead.
    if (crs case final CrsWithStaticTransformation crs) {
      final v = List<Offset>.filled(len, Offset.zero, growable: true);
      for (int i = 0; i < len; ++i) {
        final p = realPoints.elementAt(i);
        final (x, y) = crs.transform(p.dx + addedWorldWidth, p.dy, zoomScale);
        v[i] = Offset(x + ox + shift, y + oy);
      }
      return (v, addedWorldWidth);
    }

    final v = List<Offset>.filled(len, Offset.zero, growable: true);
    for (int i = 0; i < len; ++i) {
      final p = realPoints.elementAt(i);
      final (x, y) = crs.transform(p.dx + addedWorldWidth, p.dy, zoomScale);
      v[i] = Offset(x + ox + shift, y + oy);
    }
    return (v, addedWorldWidth);
  }
}
