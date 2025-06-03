import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

part 'marker.dart';

/// A [Marker] layer for [FlutterMap].
@immutable
class MarkerLayer extends StatelessWidget {
  /// The list of [Marker]s.
  final List<Marker> markers;

  /// Alignment of each marker relative to its normal center at [Marker.point]
  ///
  /// For example, [Alignment.topCenter] will mean the entire marker widget is
  /// located above the [Marker.point].
  ///
  /// The center of rotation (anchor) will be opposite this.
  ///
  /// Defaults to [Alignment.center]. Overriden by [Marker.alignment] if set.
  final Alignment alignment;

  /// Whether to counter rotate markers to the map's rotation, to keep a fixed
  /// orientation
  ///
  /// When `true`, markers will always appear upright and vertical from the
  /// user's perspective. Defaults to `false`. Overriden by [Marker.rotate].
  ///
  /// Note that this is not used to apply a custom rotation in degrees to the
  /// markers. Use a widget inside [Marker.child] to perform this.
  final bool rotate;

  /// Create a new [MarkerLayer] to use inside of [FlutterMap.children].
  const MarkerLayer({
    super.key,
    required this.markers,
    this.alignment = Alignment.center,
    this.rotate = false,
  });

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);
    final worldWidth = map.getWorldWidthAtZoom();

    return MobileLayerTransformer(
      child: Stack(
        children: (List<Marker> markers) sync* {
          for (final m in markers) {
            // Perform projection
            final pxPoint = map.projectAtZoom(m.point);

            Positioned? getPositioned(double worldShift) {
              final shiftedX = pxPoint.dx + worldShift;

              double height = m.height;
              double width = m.width;

              if (m.useSizeInMeters) {
                final basePoint = m.point;
                final baseOffset = map.getOffsetFromOrigin(basePoint);
                final rHeight =
                    const Distance().offset(basePoint, height / 2, 0);
                final rWidth = const Distance().offset(basePoint, width / 2, 0);

                height =
                    (baseOffset - map.getOffsetFromOrigin(rHeight)).distance *
                        2;
                width =
                    (baseOffset - map.getOffsetFromOrigin(rWidth)).distance * 2;

                final maxHeightUsingMetersPixels = m.maxHeightUsingMetersPixels;
                final maxWidthUsingMetersPixels = m.maxWidthUsingMetersPixels;
                if (maxHeightUsingMetersPixels != null &&
                    height > maxHeightUsingMetersPixels) {
                  height = maxHeightUsingMetersPixels;
                }
                if (maxWidthUsingMetersPixels != null &&
                    width > maxWidthUsingMetersPixels) {
                  width = maxWidthUsingMetersPixels;
                }

                final minHeightUsingMetersPixels = m.minHeightUsingMetersPixels;
                final minWidthUsingMetersPixels = m.minWidthUsingMetersPixels;
                if (minHeightUsingMetersPixels != null &&
                    height < minHeightUsingMetersPixels) {
                  height = minHeightUsingMetersPixels;
                }
                if (minWidthUsingMetersPixels != null &&
                    width < minWidthUsingMetersPixels) {
                  width = minWidthUsingMetersPixels;
                }
              }

              // Resolve real alignment
              // TODO: maybe just using Size, Offset, and Rect?
              final left = 0.5 * width * ((m.alignment ?? alignment).x + 1);
              final top = 0.5 * height * ((m.alignment ?? alignment).y + 1);
              final right = width - left;
              final bottom = height - top;

              // Cull if out of bounds
              if (!map.pixelBounds.overlaps(
                Rect.fromPoints(
                  Offset(shiftedX + left, pxPoint.dy - bottom),
                  Offset(shiftedX - right, pxPoint.dy + top),
                ),
              )) {
                return null;
              }

              // Shift original coordinate along worlds, then move into relative
              // to origin space
              final shiftedLocalPoint =
                  Offset(shiftedX, pxPoint.dy) - map.pixelOrigin;

              return Positioned(
                key: m.key,
                width: width,
                height: height,
                left: shiftedLocalPoint.dx - right,
                top: shiftedLocalPoint.dy - bottom,
                child: (m.rotate ?? rotate)
                    ? Transform.rotate(
                        angle: -map.rotationRad,
                        alignment: (m.alignment ?? alignment) * -1,
                        child: m.child,
                      )
                    : m.child,
              );
            }

            // Create marker in main world, unless culled
            final main = getPositioned(0);
            if (main != null) yield main;
            // It is unsafe to assume that if the main one is culled, it will
            // also be culled in all other worlds, so we must continue

            // TODO: optimization - find a way to skip these tests in some
            // obvious situations. Imagine we're in a map smaller than the
            // world, and west lower than east - in that case we probably don't
            // need to check eastern and western.

            // Repeat over all worlds (<--||-->) until culling determines that
            // that marker is out of view, and therefore all further markers in
            // that direction will also be
            if (worldWidth == 0) continue;
            for (double shift = -worldWidth;; shift -= worldWidth) {
              final additional = getPositioned(shift);
              if (additional == null) break;
              yield additional;
            }
            for (double shift = worldWidth;; shift += worldWidth) {
              final additional = getPositioned(shift);
              if (additional == null) break;
              yield additional;
            }
          }
        }(markers)
            .toList(),
      ),
    );
  }
}
