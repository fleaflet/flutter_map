import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/shared/feature_layer_utils.dart';
import 'package:latlong2/latlong.dart';

part 'marker.dart';

/// A layer for [FlutterMap] which displays custom widgets at specified
/// coordinates ([Marker]s).
@immutable
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

  // TODO: Consider whether culling before build is still necessary
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

  // TODO: I think? this means the `Marker` must be constructed `const` or have
  // a key set?
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

/// See also [RenderStack] & [RenderTransform]
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
      child.layout(const BoxConstraints(), parentUsesSize: true);
      child = (child.parentData! as _MarkerParentData).nextSibling;
    }
  }

// TODO: This is in `RenderTransform`, but I can't figure out what it
// necessarily does or whether we can take advantage of it
/*
    @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_effectiveTransform);
  }
*/

  ({Offset markerOffset, Offset alignmentOffset}) _getChildOffsets(
    _MarkerParentData childParentData,
    Size childSize,
  ) =>
      (
        markerOffset: camera.latLngToScreenOffset(childParentData.point!),
        alignmentOffset:
            ((childParentData.alignment ?? alignment) * -1).alongSize(childSize)
      );

  bool _isChildInvisible(Offset shiftedChildOffset, Size childSize) =>
      size.width <= shiftedChildOffset.dx ||
      shiftedChildOffset.dx + childSize.width <= 0 ||
      size.height <= shiftedChildOffset.dy ||
      shiftedChildOffset.dy + childSize.height <= 0;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final childParentData = child.parentData! as _MarkerParentData;

      final (:markerOffset, :alignmentOffset) =
          _getChildOffsets(childParentData, child.size);

      if (childParentData.rotate ?? rotate
          ?
          // TODO: Repeat across worlds
          result.addWithPaintTransform(
              transform: Matrix4.identity()
                ..leftTranslateByDouble(markerOffset.dx, markerOffset.dy, 0, 1)
                ..rotateZ(camera.rotationRad),
              position: position,
              hitTest: (result, transformed) {
                return child!
                    .hitTest(result, position: transformed + alignmentOffset);
              },
            )
          :
          // TODO: Fix issue of not rotating across worlds
          result.addWithPaintOffset(
              offset: markerOffset - alignmentOffset,
              position: position,
              hitTest: (result, transformed) => _workAcrossWorlds(
                camera,
                (shift) {
                  final childOffset =
                      Offset(transformed.dx + shift, transformed.dy);

                  if (_isChildInvisible(childOffset, child!.size)) {
                    return WorldWorkControl.invisible;
                  }

                  return child.hitTest(result, position: childOffset)
                      ? WorldWorkControl.hit
                      : WorldWorkControl.visible;
                },
              ),
            )) {
        return true;
      }

      child = childParentData.previousSibling;
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as _MarkerParentData;

      final (:markerOffset, :alignmentOffset) =
          _getChildOffsets(childParentData, child.size);

      if (childParentData.rotate ?? rotate) {
        // TODO: Repeat across worlds
        layer = context.pushTransform(
          needsCompositing,
          offset + markerOffset,
          Matrix4.identity()..rotateZ(camera.rotationRad),
          (context, offset) =>
              context.paintChild(child!, offset - alignmentOffset),
          oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
        );
      } else {
        // TODO: Fix issue of not rotating across worlds
        final unshiftedChildOffset = offset + markerOffset - alignmentOffset;

        _workAcrossWorlds(
          camera,
          (shift) {
            final childOffset = Offset(
              unshiftedChildOffset.dx + shift,
              unshiftedChildOffset.dy,
            );

            if (_isChildInvisible(childOffset, child!.size)) {
              return WorldWorkControl.invisible;
            }

            context.paintChild(child, childOffset);
            return WorldWorkControl.visible;
          },
        );
      }

      child = childParentData.nextSibling;
    }
  }
}

/// Perform the callback in all world copies (until stopped)
///
/// See [WorldWorkControl] for information about the callback return types.
/// Returns `true` if any result is [WorldWorkControl.hit].
///
/// Internally, the worker is invoked in the 'negative' worlds (worlds to the
/// left of the 'primary' world) until repetition is stopped, then in the
/// 'positive' worlds: <--||-->.
// TODO: Remove duplication - consider how to refactor `FeatureLayerUtils`
bool _workAcrossWorlds(
  MapCamera camera,
  WorldWorkControl Function(double shift) work,
) {
  // Protection in case of unexpected infinite loop if `work` never returns
  // `invisible`. e.g. https://github.com/fleaflet/flutter_map/issues/2052.
  //! This can produce false positives - but it's better than a crash.
  const maxShiftsCount = 30;
  int shiftsCount = 0;

  final worldWidth = camera.getWorldWidthAtZoom();

  void protectInfiniteLoop() {
    if (++shiftsCount > maxShiftsCount) {
      throw AssertionError(
        'Infinite loop going beyond $maxShiftsCount for world width $worldWidth',
      );
    }
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
