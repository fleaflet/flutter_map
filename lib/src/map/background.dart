import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/shared/mobile_layer_transformer.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:meta/meta.dart';

/// The map background, covered by map layers as they render.
@internal
class MapBackground extends StatelessWidget {
  /// Creates the map background and its optional grid.
  const MapBackground({
    super.key,
    required this.color,
    required this.gridColor,
    required this.gridSpacing,
  });

  /// The background fill color.
  final Color color;

  /// The grid line color, or `null` to disable the grid.
  final Color? gridColor;

  /// The grid cell size at integer zoom levels.
  final double gridSpacing;

  @override
  Widget build(BuildContext context) {
    final gridColor = this.gridColor;
    if (gridColor == null || gridColor.a == 0 || color.a == 0) {
      return ColoredBox(color: color);
    }
    final camera = MapCamera.of(context);

    return RepaintBoundary(
      child: ColoredBox(
        color: color,
        child: IgnorePointer(
          child: MobileLayerTransformer(
            child: CustomPaint(
              painter: _BackgroundGridPainter(
                color: gridColor,
                spacing: gridSpacing *
                    camera.getZoomScale(
                      camera.zoom,
                      camera.zoom.floorToDouble(),
                    ),
                pixelOrigin: camera.pixelOrigin,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundGridPainter extends CustomPainter {
  const _BackgroundGridPainter({
    required this.color,
    required this.spacing,
    required this.pixelOrigin,
  });

  final Color color;
  final double spacing;
  final Offset pixelOrigin;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !spacing.isFinite || spacing < 1) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path();

    // Reduce the projected coordinates before drawing so the work depends on
    // viewport size, even at high zoom levels or across repeated worlds.
    for (var x = -pixelOrigin.dx % spacing; x < size.width; x += spacing) {
      path
        ..moveTo(x, 0)
        ..lineTo(x, size.height);
    }
    for (var y = -pixelOrigin.dy % spacing; y < size.height; y += spacing) {
      path
        ..moveTo(0, y)
        ..lineTo(size.width, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BackgroundGridPainter oldDelegate) =>
      color != oldDelegate.color ||
      spacing != oldDelegate.spacing ||
      pixelOrigin != oldDelegate.pixelOrigin;
}
