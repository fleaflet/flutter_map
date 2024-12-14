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

    return MobileLayerTransformer(
      child: Stack(
        children: (List<Marker> markers) sync* {
          final double worldWidth = map.getWorldWidthAtZoom();
          for (final m in markers) {
            // Resolve real alignment
            // TODO this can probably just be done with calls to Size, Offset, and Rect
            final left = 0.5 * m.width * ((m.alignment ?? alignment).x + 1);
            final top = 0.5 * m.height * ((m.alignment ?? alignment).y + 1);
            final right = m.width - left;
            final bottom = m.height - top;

            // Perform projection
            final pxPoint = map.projectAtZoom(m.point);

            Positioned? getPositioned(final num? deltaX) {
              final otherX = pxPoint.dx + (deltaX ?? 0);
              // Cull if out of bounds
              if (!map.pixelBounds.overlaps(
                Rect.fromPoints(
                  Offset(otherX + left, pxPoint.dy - bottom),
                  Offset(otherX - right, pxPoint.dy + top),
                ),
              )) {
                return null;
              }

              final otherPoint =
                  deltaX == null ? pxPoint : Offset(otherX, pxPoint.dy);
              // Apply map camera to marker position
              final pos = otherPoint - map.pixelOrigin;

              return Positioned(
                key: m.key,
                width: m.width,
                height: m.height,
                left: pos.dx - right,
                top: pos.dy - bottom,
                child: (m.rotate ?? rotate)
                    ? Transform.rotate(
                        angle: -map.rotationRad,
                        alignment: (m.alignment ?? alignment) * -1,
                        child: m.child,
                      )
                    : m.child,
              );
            }

            final main = getPositioned(null);
            if (main == null) {
              continue;
            }
            yield main;

            if (worldWidth == 0) {
              continue;
            }

            const directions = <int>[-1, 1];
            for (final int direction in directions) {
              double shift = 0;
              while (true) {
                shift += direction * worldWidth;
                final additional = getPositioned(shift);
                if (additional == null) {
                  break;
                }
                yield additional;
              }
            }
          }
        }(markers)
            .toList(),
      ),
    );
  }
}
