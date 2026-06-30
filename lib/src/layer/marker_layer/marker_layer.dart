import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

part 'marker.dart';

/// A [Marker] layer for [FlutterMap].
@immutable
class MarkerLayer extends StatefulWidget {
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
  State<MarkerLayer> createState() => _MarkerLayerState();
}

class _MarkerLayerState extends State<MarkerLayer> {
  /// Projected (zoom-independent) coordinates of every [Marker.point], in the
  /// same order as the markers list
  ///
  /// Projecting a point is relatively expensive (it involves trigonometry),
  /// but only depends on the CRS - not on the camera position or zoom. Caching
  /// it means each camera movement only costs the cheap linear
  /// projected -> screen transformation per marker, instead of a full
  /// re-projection.
  List<Offset>? _projectedPoints;
  Crs? _projectionCrs;

  @override
  void didUpdateWidget(MarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Matches the invalidation convention of the polyline/polygon layers: any
    // new widget instance re-projects, so in-place mutations of the markers
    // list keep working as they did when projection was performed per-frame.
    _projectedPoints = null;
  }

  List<Offset> _projectPoints(Crs crs) {
    final projection = crs.projection;
    return List<Offset>.generate(
      widget.markers.length,
      (i) {
        final point = widget.markers[i].point;
        // Guard against memory leaks (see
        // https://github.com/fleaflet/flutter_map/issues/2178)
        if (!(point.latitude.isFinite && point.longitude.isFinite)) {
          throw RangeError('All markers must have finite `point`s');
        }
        return projection.project(point);
      },
      growable: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);
    final crs = map.crs;

    if (_projectedPoints == null || _projectionCrs != crs) {
      _projectionCrs = crs;
      _projectedPoints = _projectPoints(crs);
    }
    final projectedPoints = _projectedPoints!;

    final worldWidth = map.getWorldWidthAtZoom();
    final zoomScale = crs.scale(map.zoom);
    final pixelBounds = map.pixelBounds;
    final pixelOrigin = map.pixelOrigin;
    final markers = widget.markers;

    return MobileLayerTransformer(
      child: Stack(
        children: () sync* {
          for (var i = 0; i < markers.length; i++) {
            final m = markers[i];

            // Resolve real alignment
            // TODO: maybe just using Size, Offset, and Rect?
            final left =
                0.5 * m.width * ((m.alignment ?? widget.alignment).x + 1);
            final top =
                0.5 * m.height * ((m.alignment ?? widget.alignment).y + 1);
            final right = m.width - left;
            final bottom = m.height - top;

            // Scale the cached projection to the current zoom
            final projected = projectedPoints[i];
            final (px, py) =
                crs.transform(projected.dx, projected.dy, zoomScale);
            final pxPoint = Offset(px, py);

            Positioned? getPositioned(double worldShift) {
              final shiftedX = pxPoint.dx + worldShift;

              // Cull if out of bounds
              if (!pixelBounds.overlaps(
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
                  Offset(shiftedX, pxPoint.dy) - pixelOrigin;

              return Positioned(
                key: m.key,
                width: m.width,
                height: m.height,
                left: shiftedLocalPoint.dx - right,
                top: shiftedLocalPoint.dy - bottom,
                child: (m.rotate ?? widget.rotate)
                    ? Transform.rotate(
                        angle: -map.rotationRad,
                        alignment: (m.alignment ?? widget.alignment) * -1,
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
        }()
            .toList(),
      ),
    );
  }
}
