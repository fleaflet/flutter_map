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
  /// See [WorldWorkControl] for information about the callback return types.
  /// Returns `true` if any result is [WorldWorkControl.hit].
  ///
  /// Internally, the worker is invoked in the 'negative' worlds (worlds to the
  /// left of the 'primary' world) until repetition is stopped, then in the
  /// 'positive' worlds: <--||-->.
  bool workAcrossWorlds(
    WorldWorkControl Function(double shift) work,
  ) {
    // Protection in case of unexpected infinite loop if `work` never returns
    // `invisible`. e.g. https://github.com/fleaflet/flutter_map/issues/2052.
    //! This can produce false positives - but it's better than a crash.
    const maxShiftsCount = 30;
    int shiftsCount = 0;

    void protectInfiniteLoop() {
      if (++shiftsCount > maxShiftsCount) throw const StackOverflowError();
    }

    protectInfiniteLoop();
    if (work(0) == WorldWorkControl.hit) return true;

    if (worldWidth == 0) return false;

    negativeWorldsLoop:
    for (double shift = -worldWidth;; shift -= worldWidth) {
      protectInfiniteLoop();
      switch (work(shift)) {
        case WorldWorkControl.hit:
          return true;
        case WorldWorkControl.invisible:
          break negativeWorldsLoop;
        case WorldWorkControl.visible:
      }
    }

    for (double shift = worldWidth;; shift += worldWidth) {
      protectInfiniteLoop();
      switch (work(shift)) {
        case WorldWorkControl.hit:
          return true;
        case WorldWorkControl.invisible:
          return false;
        case WorldWorkControl.visible:
      }
    }
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

/// Return type for the callback argument of
/// [FeatureLayerUtils.workAcrossWorlds], which indicates how to control the
/// iteration across worlds & how to return from the method
///
/// The callback must return [hit] or [invisible] in some case to prevent an
/// infinite loop.
@internal
enum WorldWorkControl {
  /// Immediately stop iteration across all further worlds, and return `true`
  ///
  /// This is useful for hit testing for efficiency purposes, where hitting any
  /// one element is enough to determine a hit testing result.
  hit,

  /// Keep iterating across worlds in the current direction
  visible,

  /// Stop iterating across worlds in the current direction; if both directions
  /// have been completed without a [hit], returns `false`
  invisible,
}
