part of 'placeholder_grid_layer.dart';

class _BackgroundGridPainter extends CustomPainter {
  const _BackgroundGridPainter({
    required this.color,
    required this.spacing,
    required this.pixelOrigin,
    required this.numOfMinors,
    required this.majorStrokeWidth,
    required this.minorStrokeWidth,
  });

  final Color color;
  final double spacing;
  final Offset? pixelOrigin;
  final int numOfMinors;
  final double majorStrokeWidth;
  final double minorStrokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !spacing.isFinite || spacing < 1) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = majorStrokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false;
    final path = Path();

    double x = -(pixelOrigin == null ? size.width : pixelOrigin!.dx % spacing);
    for (; x < size.width; x += spacing) {
      path
        ..moveTo(x, 0)
        ..lineTo(x, size.height);
    }
    double y = -(pixelOrigin == null ? size.height : pixelOrigin!.dy % spacing);
    for (; y < size.height; y += spacing) {
      path
        ..moveTo(0, y)
        ..lineTo(size.width, y);
    }

    canvas.drawPath(path, paint);

    if (numOfMinors == 0) return;

    path.reset();

    final minorSpacing = spacing / (numOfMinors + 1);

    x = -(pixelOrigin == null ? size.width : pixelOrigin!.dx % minorSpacing);
    for (; x < size.width; x += minorSpacing) {
      path
        ..moveTo(x, 0)
        ..lineTo(x, size.height);
    }
    y = -(pixelOrigin == null ? size.height : pixelOrigin!.dy % minorSpacing);
    for (; y < size.height; y += minorSpacing) {
      path
        ..moveTo(0, y)
        ..lineTo(size.width, y);
    }

    canvas.drawPath(path, paint..strokeWidth = minorStrokeWidth);
  }

  @override
  bool shouldRepaint(_BackgroundGridPainter oldDelegate) =>
      color != oldDelegate.color ||
      spacing != oldDelegate.spacing ||
      pixelOrigin != oldDelegate.pixelOrigin ||
      numOfMinors != oldDelegate.numOfMinors ||
      majorStrokeWidth != oldDelegate.majorStrokeWidth ||
      minorStrokeWidth != oldDelegate.majorStrokeWidth;
}
