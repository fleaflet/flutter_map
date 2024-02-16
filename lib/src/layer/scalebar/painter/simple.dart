part of '../scalebar.dart';

/// This is the [CustomPainter] that draws the scalebar label and lines
/// onto the canvas.
class _ScalebarPainter extends CustomPainter {
  final double width;
  final String text;
  final double strokeWidth;
  final double lineHeight;
  final TextStyle? textStyle;

  final Paint _linePaint;

  /// Create a new [Scalebar], internally used in the [Scalebar].
  _ScalebarPainter({
    required this.width,
    required this.text,
    required this.textStyle,
    required this.strokeWidth,
    required this.lineHeight,
    required Color lineColor,
  }) : _linePaint = Paint()
          ..color = lineColor
          ..strokeCap = StrokeCap.square
          ..strokeWidth = strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    const topPaddingCorr = -5.0;
    final halfStrokeWidth = strokeWidth / 2;

    // draw text label
    final textPainter = TextPainter(
      text: TextSpan(style: textStyle, text: text),
      textDirection: TextDirection.ltr,
    )..layout();
    final x = width / 2 - textPainter.width / 2 + halfStrokeWidth;
    textPainter.paint(
      canvas,
      Offset(max(0, x), topPaddingCorr),
    );

    final paddingTop = topPaddingCorr + textPainter.height;
    final leftLineBottom = Offset(
      halfStrokeWidth,
      lineHeight + paddingTop,
    );
    final rightLineBottom = Offset(
      width + halfStrokeWidth,
      lineHeight + paddingTop,
    );

    final middleX = (leftLineBottom.dx + rightLineBottom.dx) / 2;

    // 4 lines * 2 offsets * 2 coordinates
    final linePoints = Float32List.fromList(<double>[
      // left vertical line
      leftLineBottom.dx,
      paddingTop,
      leftLineBottom.dx,
      leftLineBottom.dy,
      // right vertical line
      rightLineBottom.dx,
      paddingTop,
      rightLineBottom.dx,
      rightLineBottom.dy,
      // middle vertical line
      middleX,
      paddingTop + lineHeight / 2,
      middleX,
      leftLineBottom.dy,
      // bottom horizontal line
      leftLineBottom.dx,
      leftLineBottom.dy,
      rightLineBottom.dx,
      rightLineBottom.dy,
    ]);

    // draw lines as raw points
    canvas.drawRawPoints(
      PointMode.lines,
      linePoints,
      _linePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
