part of '../polygon_layer.dart';

void Function(Canvas canvas)? _buildLabelTextPainter({
  required Size mapSize,
  required Offset placementPoint,
  required ({Offset min, Offset max}) bounds,
  required TextPainter textPainter,
  required double rotationRad,
  required bool rotate,
  required double padding,
}) {
  final dx = placementPoint.dx;
  final dy = placementPoint.dy;
  final width = textPainter.width;
  final height = textPainter.height;

  // Cull labels where the polygon is still on the map but the label would not be.
  // Currently this is only enabled when the map isn't rotated, since the placementOffset
  // is relative to the MobileLayerTransformer rather than in actual screen coordinates.
  final double textWidth;
  final double textHeight;
  final double mapWidth;
  final double mapHeight;
  if (rotationRad == 0) {
    textWidth = width;
    textHeight = height;
    mapWidth = mapSize.width;
    mapHeight = mapSize.height;
  } else {
    // lazily we imagine the worst case scenario regarding sizes, instead of
    // computing the angles
    textWidth = textHeight = max(width, height);
    mapWidth = mapHeight = max(mapSize.width, mapSize.height);
  }
  if (dx + textWidth / 2 < 0 || dx - textWidth / 2 > mapWidth) {
    return null;
  }
  if (dy + textHeight / 2 < 0 || dy - textHeight / 2 > mapHeight) {
    return null;
  }

  // Note: I'm pretty sure this doesn't work for concave shapes. It would be more
  // correct to evaluate the width of the polygon at the height of the label.
  if (bounds.max.dx - bounds.min.dx - padding > width) {
    return (canvas) {
      if (rotate) {
        canvas.save();
        canvas.translate(dx, dy);
        canvas.rotate(-rotationRad);
        canvas.translate(-dx, -dy);
      }

      textPainter.paint(
        canvas,
        Offset(
          dx - width / 2,
          dy - height / 2,
        ),
      );

      if (rotate) {
        canvas.restore();
      }
    };
  }
  return null;
}
