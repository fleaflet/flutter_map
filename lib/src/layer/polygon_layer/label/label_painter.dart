part of '../polygon_layer.dart';

/// Draws the labels of a pitched map's polygons in screen space, so that they
/// face the viewer instead of lying on the ground
class _PolygonLabelPainter<R extends Object> extends CustomPainter
    with FeatureLayerUtils {
  _PolygonLabelPainter({required this.polygons, required this.camera})
      : _helper = OffsetHelper(camera: camera);

  final List<_ProjectedPolygon<R>> polygons;

  @override
  final MapCamera camera;

  final OffsetHelper _helper;

  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);

    final origin = camera.pixelOrigin;
    final canvasToScreen = camera.pixelToScreenTransform
      ..translateByDouble(origin.dx, origin.dy, 0, 1);

    for (final projectedPolygon in polygons) {
      final polygon = projectedPolygon.polygon;
      final textPainter = polygon.textPainter;
      if (projectedPolygon.points.isEmpty || textPainter == null) continue;

      final bBox = polygon.boundingBox;
      final bounds = (
        min: _helper.getOffset(bBox.southWest),
        max: _helper.getOffset(bBox.northEast),
      );

      workAcrossWorlds((shift) {
        final point = _helper.getOffset(polygon.labelPosition, shift: shift);
        // A point behind the camera has no screen position
        if (canvasToScreen.storage[3] * point.dx +
                canvasToScreen.storage[7] * point.dy +
                canvasToScreen.storage[15] <=
            0) {
          return WorldWorkControl.invisible;
        }

        // In screen space, a label that turns with the map is rotated and an
        // upright label is not: the reverse of the unpitched painter.
        final painter = _buildLabelTextPainter(
          mapSize: size,
          placementPoint: MatrixUtils.transformPoint(canvasToScreen, point),
          bounds: bounds,
          textPainter: textPainter,
          rotationRad: -camera.rotationRad,
          rotate: !polygon.rotateLabel,
          padding: 20,
        );
        if (painter == null) return WorldWorkControl.invisible;
        painter(canvas);
        return WorldWorkControl.visible;
      });
    }
  }

  // Labels don't take part in hit testing, so taps reach the polygons below.
  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_PolygonLabelPainter<R> oldDelegate) =>
      polygons != oldDelegate.polygons || camera != oldDelegate.camera;
}
