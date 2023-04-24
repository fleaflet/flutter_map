import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';


/// General purpose map layer for rendering multiple widgets using the [WidgetLayerPositioned] widget.

class WidgetLayer extends MultiChildRenderObjectWidget {
  WidgetLayer({
    super.children,
    super.key,
  });

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderWidgetLayer(
    map: FlutterMapState.maybeOf(context)!,
  );

  @override
  void updateRenderObject(BuildContext context, covariant _RenderWidgetLayer renderObject) {
    renderObject.map = FlutterMapState.maybeOf(context)!;
  }
}

class _RenderWidgetLayer extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _WidgetLayerParentData>,
         RenderBoxContainerDefaultsMixin<RenderBox, _WidgetLayerParentData> {
  _RenderWidgetLayer({
    required FlutterMapState map,
    List<RenderBox>? children,
  }) : _map = map {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _WidgetLayerParentData) {
      child.parentData = _WidgetLayerParentData();
    }
  }

  double? _prevZoom;
  LatLng? _prevPos;

  FlutterMapState get map => _map;
  FlutterMapState _map;
  set map(FlutterMapState value) {
    if (_prevZoom != value.zoom) {
      _prevZoom = value.zoom;
      markNeedsLayout();
    }
    if (_prevPos != value.center) {
      _prevPos = value.center;
      markNeedsPaint();
    }
    if (_map != value) {
      _map = value;
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as _WidgetLayerParentData;
      _layoutChild(child);
      child = childParentData.nextSibling;
    }
  }

  void _layoutChild(RenderBox child) {
    final childParentData = child.parentData! as _WidgetLayerParentData;
    final BoxConstraints childConstraints;

    // if size in meters is specified
    if (childParentData.size != null && childParentData.position != null) {
      // calc tight size constraints
      final size = _calcSizeFromMeters(childParentData.size!, childParentData.position!, map.zoom);
      childConstraints = BoxConstraints.tight(size);
    }
    // else use infinite constraints for child
    else {
      childConstraints = const BoxConstraints();
    }

    child.layout(childConstraints, parentUsesSize: true);

    // calculate pixel position of child
    final pxPoint = map.project(childParentData.position!);
    // shift position to center
    final center = Offset(pxPoint.x.toDouble() - child.size.width/2, pxPoint.y.toDouble() - child.size.height/2);
    // write global pixel offset
    childParentData.offset = center;
  }

  // earth circumference in meters
  static const _earthCircumference = 2 * pi * earthRadius;

  static const _piFraction = pi / 180;

  double _metersPerPixel(double latitude, double zoomLevel) {
    final latitudeRadians = latitude * _piFraction;
    return _earthCircumference * cos(latitudeRadians) / pow(2, zoomLevel + 8);
  }

  Size _calcSizeFromMeters(Size size, LatLng point, double zoom) {
    return size / _metersPerPixel(point.latitude, zoom);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    // transform to global pixel offset
    // because defaultHitTestChildren operates on the offset of the _WidgetLayerParentData
    // which we set to global pixels on layout
    position = position.translate(
      map.pixelOrigin.x.toDouble(),
      map.pixelOrigin.y.toDouble(),
    );
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // transform to local pixel offset
    offset = offset.translate(
      -map.pixelOrigin.x.toDouble(),
      -map.pixelOrigin.y.toDouble(),
    );
    // for performance improvements the layer is not clipped
    // instead the whole map widget should be clipped

    // this is an altered version of defaultPaint(context, offset);
    // which does not paint children outside the map layer viewport
    final layerViewport = Rect.fromLTWH(
      map.pixelOrigin.x.toDouble(),
      map.pixelOrigin.y.toDouble(),
      map.size.x,
      map.size.y,
    );
    var child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as _WidgetLayerParentData;
      final childRect = childParentData.offset & child.size;
      // only render child if bounds are inside the viewport
      // note this does not properly work for children that draw outside of their bounds (e.g. shadows)
      if (layerViewport.overlaps(childRect)) {
        context.paintChild(child, childParentData.offset + offset);
      }
      child = childParentData.nextSibling;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('map', map));
  }
}

/// Widget to position other [Widget]s on a [WidgetLayer].
///
/// The parent [WidgetLayer] widget will handle the positioning.
///
/// The [size] property specifies the widgets dimensions in meters. This means the widget size changes on zoom.
///
/// If [size] is omitted the intrinsic size of [child] will be used. This means the size will **not** change on zoom.

class WidgetLayerPositioned extends ParentDataWidget<_WidgetLayerParentData> {
  final LatLng position;

  final Size? size;

  const WidgetLayerPositioned({
    required this.position,
    required super.child,
    this.size,
    super.key,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is _WidgetLayerParentData);
    final _WidgetLayerParentData parentData = renderObject.parentData! as _WidgetLayerParentData;
    assert(renderObject.parent is RenderObject);
    final targetParent = renderObject.parent! as RenderObject;

    if (parentData.size != size) {
      parentData.size = size;
      targetParent.markNeedsLayout();
    }

    if (parentData.position != position) {
      parentData.position = position;
      if (parentData.size != null) {
        // size depends on the geo location, therefore re-layout if size is set in meters
        targetParent.markNeedsLayout();
      }
      else {
        targetParent.markNeedsPaint();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => WidgetLayer;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('position', position));
    properties.add(DiagnosticsProperty('size', size));
  }
}


class _WidgetLayerParentData extends ContainerBoxParentData<RenderBox> {
  LatLng? position;

  Size? size;
}
