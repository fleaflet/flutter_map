import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Provides utilities for 'feature layers' implemented with canvas painters and
/// hit testers, especially those which have multi-world support
@internal
mixin FeatureLayerUtils on CustomPainter {
  abstract final MapCamera camera;
  static const _distance = Distance();

  /// The rectangle of the canvas on its last paint
  ///
  /// Must not be retrieved before [paint] has been called.
  Rect get viewportRect => _viewportRect;
  late Rect _viewportRect;

  @mustCallSuper
  @mustBeOverridden
  @override
  void paint(Canvas canvas, Size size) {
    _viewportRect = Offset.zero & size;
  }

  /// Determine whether the specified offsets are visible within the viewport
  ///
  /// Always returns `false` if the specified list is empty.
  bool areOffsetsVisible(Iterable<Offset> offsets) {
    if (offsets.isEmpty) {
      return false;
    }
    double minX;
    double maxX;
    double minY;
    double maxY;
    minX = maxX = offsets.first.dx;
    minY = maxY = offsets.first.dy;
    for (final Offset offset in offsets) {
      if (viewportRect.contains(offset)) return true;
      if (minX > offset.dx) minX = offset.dx;
      if (minY > offset.dy) minY = offset.dy;
      if (maxX < offset.dx) maxX = offset.dx;
      if (maxY < offset.dy) maxY = offset.dy;
    }
    return viewportRect.overlaps(Rect.fromLTRB(minX, minY, maxX, maxY));
  }

  /// Perform the callback in all world copies (until stopped)
  ///
  /// If the worker returns:
  ///  * `true`: no more worlds will be tested, and this will return `true`
  ///  * `false`: more worlds will be tested
  ///  * `null`: no more worlds will be tested in the current working direction;
  /// if both directions have been finished, this will return `false`
  ///
  /// The worker must return `true` or `null` in some case to prevent an
  /// infinite loop.
  ///
  /// Internally, the worker is invoked in the 'negative' worlds (worlds to the
  /// left of the 'primary' world) until repetition is stopped, then in the
  /// 'positive' world: <--||-->.
  bool workAcrossWorlds(bool? Function(double shift) work) {
    if (work(0) ?? false) {
      return true;
    }

    if (worldWidth == 0) return false;
    for (double shift = -worldWidth;; shift -= worldWidth) {
      final isHit = work(shift);
      if (isHit == null) break;
      if (isHit) return true;
    }
    for (double shift = worldWidth;; shift += worldWidth) {
      final isHit = work(shift);
      if (isHit == null) break;
      if (isHit) return true;
    }

    return false;
  }

  /// Returns the origin of the camera.
  Offset get origin =>
      camera.projectAtZoom(camera.center) - camera.size.center(Offset.zero);

  /// Returns the world size in pixels.
  ///
  /// Equivalent to [MapCamera.getWorldWidthAtZoom].
  double get worldWidth => camera.getWorldWidthAtZoom();

  /// Converts a distance in meters to the equivalent distance in screen pixels,
  /// at the geographic coordinates specified.
  double metersToScreenPixels(LatLng point, double meters) =>
      (camera.getOffsetFromOrigin(point) -
              camera.getOffsetFromOrigin(_distance.offset(point, meters, 180)))
          .distance;
}
