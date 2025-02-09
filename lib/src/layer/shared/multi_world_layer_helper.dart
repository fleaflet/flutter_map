import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Helper for multi world: e.g. draw and hitTest on all world copies.
class MultiWorldLayerHelper {
  /// Helper for multi world.
  MultiWorldLayerHelper(this.camera);

  static const _distance = Distance();

  /// Sets the screen size. To be called immediately after `paint`.
  void setSize(Size size) => _screenRect = Offset.zero & size;

  late Rect _screenRect;

  /// Screen rect.
  Rect get screenRect => _screenRect;

  /// Camera.
  final MapCamera camera;

  /// Returns true if the points are visible on the screen.
  bool isVisible(List<Offset> points) {
    if (points.isEmpty) {
      return false;
    }
    double minX;
    double maxX;
    double minY;
    double maxY;
    minX = maxX = points.first.dx;
    minY = maxY = points.first.dy;
    for (final Offset offset in points) {
      if (screenRect.contains(offset)) return true;
      if (minX > offset.dx) minX = offset.dx;
      if (minY > offset.dy) minY = offset.dy;
      if (maxX < offset.dx) maxX = offset.dx;
      if (maxY < offset.dy) maxY = offset.dy;
    }
    return screenRect.overlaps(Rect.fromLTRB(minX, minY, maxX, maxY));
  }

  /// Returns true if hit in all world copies.
  ///
  /// Uses a "single-world" method that returns*
  /// * null if invisible
  /// * true if hit
  /// * false if not hit
  bool checkIfHitInTheWorlds(bool? Function(double) checkIfHit) {
    if (checkIfHit(0) ?? false) {
      return true;
    }

    // Repeat over all worlds (<--||-->) until culling determines that
    // that element is out of view, and therefore all further elements in
    // that direction will also be
    if (worldWidth == 0) return false;
    for (double shift = -worldWidth;; shift -= worldWidth) {
      final isHit = checkIfHit(shift);
      if (isHit == null) break;
      if (isHit) return true;
    }
    for (double shift = worldWidth;; shift += worldWidth) {
      final isHit = checkIfHit(shift);
      if (isHit == null) break;
      if (isHit) return true;
    }

    return false;
  }

  /// Draws in all world copies.
  ///
  /// Uses a "single-world" method that returns*
  /// * true if visible
  /// * false if not visible
  void drawInTheWorlds(bool Function(double) drawIfVisible) {
    drawIfVisible(0);

    if (worldWidth == 0) return;
    for (double shift = -worldWidth;; shift -= worldWidth) {
      final isVisible = drawIfVisible(shift);
      if (!isVisible) break;
    }
    for (double shift = worldWidth;; shift += worldWidth) {
      final isVisible = drawIfVisible(shift);
      if (!isVisible) break;
    }
  }

  /// Returns the origin of the camera.
  Offset get origin =>
      camera.projectAtZoom(camera.center) - camera.size.center(Offset.zero);

  /// Returns the world size in pixels.
  double get worldWidth => camera.getWorldWidthAtZoom();

  /// Returns the width in pixel of a width in meters, for a given [point].
  double getPixelWidthFromMeters(LatLng point, double meters) =>
      (camera.getOffsetFromOrigin(point) -
              camera.getOffsetFromOrigin(_distance.offset(point, meters, 180)))
          .distance;
}
