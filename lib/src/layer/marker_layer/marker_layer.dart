import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

part 'marker.dart';

class MarkerLayer extends MultiChildRenderObjectWidget {
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
  List<Widget> get children =>
      markers.map((m) => _MarkerWidget(marker: m)).toList(growable: false);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MarkerLayerRenderBox(
        camera: MapCamera.of(context),
        alignment: alignment,
        rotate: rotate,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    // ignore: library_private_types_in_public_api
    covariant _MarkerLayerRenderBox renderObject,
  ) {
    final latestCamera = MapCamera.of(context);
    if (latestCamera != renderObject.camera) {
      renderObject.camera = latestCamera;
    }

    if (alignment != renderObject.alignment) {
      renderObject.alignment = alignment;
    }

    if (rotate != renderObject.rotate) {
      renderObject.rotate = rotate;
    }
  }
}

class _MarkerWidget extends ParentDataWidget<_MarkerParentData> {
  _MarkerWidget({required this.marker}) : super(child: marker.child);

  final Marker marker;

  @override
  Key? get key => marker.key ?? ObjectKey(marker);

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData! as _MarkerParentData;
    bool needsLayout = false;

    if (parentData.point != marker.point) {
      parentData.point = marker.point;
      needsLayout = true;
    }
    if (parentData.alignment != marker.alignment) {
      parentData.alignment = marker.alignment;
      needsLayout = true;
    }
    if (parentData.rotate != marker.rotate) {
      parentData.rotate = marker.rotate;
      needsLayout = true;
    }

    if (needsLayout) renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => MarkerLayer;
}

class _MarkerParentData extends ParentData
    with ContainerParentDataMixin<RenderBox> {
  LatLng? point;
  Alignment? alignment;
  bool? rotate;
}

class _MarkerLayerRenderBox extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _MarkerParentData> {
  _MarkerLayerRenderBox({
    required MapCamera camera,
    required Alignment alignment,
    required bool rotate,
  })  : _camera = camera,
        _alignment = alignment,
        _rotate = rotate;

  MapCamera get camera => _camera;
  MapCamera _camera;
  set camera(MapCamera value) {
    if (value == _camera) return;
    _camera = value;
    markNeedsPaint();
  }

  Alignment get alignment => _alignment;
  Alignment _alignment;
  set alignment(Alignment value) {
    if (value == _alignment) return;
    _alignment = value;
    markNeedsPaint();
  }

  bool get rotate => _rotate;
  bool _rotate;
  set rotate(bool value) {
    if (value == _rotate) return;
    _rotate = value;
    markNeedsPaint();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _MarkerParentData) {
      child.parentData = _MarkerParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;

    var child = firstChild;
    while (child != null) {
      // If the child expands, it is constrained to the maximum non rotated size
      // TODO: This is probably unwanted, find a way to force children to define
      // their size
      child.layout(constraints.loosen(), parentUsesSize: true);
      child = (child.parentData! as ContainerParentDataMixin<RenderBox>)
          .nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final markerData = child.parentData! as _MarkerParentData;

      final markerOffset = camera.latLngToScreenOffset(markerData.point!);
      // We need to apply this, but if we're rotating, we want to do that first
      final alignmentOffset =
          ((markerData.alignment ?? alignment) * -1).alongSize(child.size);

      if (markerData.rotate ?? rotate) {
        context.pushTransform(
          needsCompositing,
          offset + markerOffset,
          Matrix4.identity()..rotateZ(camera.rotationRad),
          (context, transformOffset) =>
              context.paintChild(child!, transformOffset - alignmentOffset),
        );
      } else {
        final childOffset = offset + markerOffset - alignmentOffset;

        bool paintIfVisible(double worldShift) {
          final shiftedX = childOffset.dx + worldShift;

          // Cull if out of bounds
          // TODO: Verify
          // TODO: Copy to transformed logic also
          if (size.width <= shiftedX || shiftedX + child!.size.width <= 0) {
            return false;
          }
          if (size.height <= childOffset.dy ||
              childOffset.dy + child.size.height <= 0) {
            return false;
          }

          context.paintChild(child, Offset(shiftedX, childOffset.dy));
          return true;
        }

        // Create marker in main world, unless culled
        final main = paintIfVisible(0);
        if (!main) {
          child = markerData.nextSibling;
          continue;
        }
        // It is unsafe to assume that if the main one is culled, it will
        // also be culled in all other worlds, so we must continue

        // TODO: optimization - find a way to skip these tests in some
        // obvious situations. Imagine we're in a map smaller than the
        // world, and west lower than east - in that case we probably don't
        // need to check eastern and western.

        final worldWidth = camera.getWorldWidthAtZoom();

        // Repeat over all worlds (<--||-->) until culling determines that
        // that marker is out of view, and therefore all further markers in
        // that direction will also be
        if (worldWidth == 0) continue;
        for (double shift = -worldWidth;; shift -= worldWidth) {
          final additional = paintIfVisible(shift);
          if (!additional) break;
        }
        for (double shift = worldWidth;; shift += worldWidth) {
          final additional = paintIfVisible(shift);
          if (!additional) break;
        }
      }

      child = markerData.nextSibling;
    }
  }
}

/*/// A [Marker] layer for [FlutterMap].
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
            // Resolve real alignment
            // TODO: maybe just using Size, Offset, and Rect?
            final left = 0.5 * m.width * ((m.alignment ?? alignment).x + 1);
            final top = 0.5 * m.height * ((m.alignment ?? alignment).y + 1);
            final right = m.width - left;
            final bottom = m.height - top;

            // Perform projection
            final pxPoint = map.projectAtZoom(m.point);

            Positioned? getPositioned(double worldShift) {
              final shiftedX = pxPoint.dx + worldShift;

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
                width: m.width,
                height: m.height,
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
*/
