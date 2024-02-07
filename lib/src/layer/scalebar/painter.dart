part of 'scalebar.dart';

/// This is the [CustomPainter] that draws the scalebar label and lines
/// onto the canvas.
class ScalebarPainter extends CustomPainter {
  final double width;
  final EdgeInsets padding;
  final String text;
  final double strokeWidth;
  final double lineHeight;
  final Color lineColor;
  final TextStyle? textStyle;

  final Paint _linePaint;

  /// Create a new [ScalebarPainter], internally used in the [Scalebar].
  ScalebarPainter({
    required this.width,
    required this.text,
    required this.padding,
    required this.textStyle,
    required this.strokeWidth,
    required this.lineHeight,
    required this.lineColor,
  }) : _linePaint = Paint()
          ..color = lineColor
          ..strokeCap = StrokeCap.square
          ..strokeWidth = strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    const topPaddingCorr = -5;
    final paddingLeft = padding.left;
    var paddingTop = padding.top + topPaddingCorr;
    final halfStrokeWidth = strokeWidth / 2;

    // draw text label
    final textSpan = TextSpan(style: textStyle, text: text);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        width / 2 - textPainter.width / 2 + paddingLeft + halfStrokeWidth,
        paddingTop,
      ),
    );

    paddingTop += textPainter.height;
    final leftLineBottom = Offset(
      paddingLeft + halfStrokeWidth,
      lineHeight + paddingTop,
    );
    final rightLineBottom = Offset(
      paddingLeft + width + halfStrokeWidth,
      lineHeight + paddingTop,
    );

    // draw start line
    canvas.drawLine(
      Offset(leftLineBottom.dx, paddingTop),
      leftLineBottom,
      _linePaint,
    );

    // draw end line
    canvas.drawLine(
      Offset(rightLineBottom.dx, paddingTop),
      rightLineBottom,
      _linePaint,
    );

    // draw middle line
    final middleX = (leftLineBottom.dx + rightLineBottom.dx) / 2;
    canvas.drawLine(
      Offset(middleX, paddingTop + lineHeight / 2),
      Offset(middleX, leftLineBottom.dy),
      _linePaint,
    );

    // draw bottom line
    canvas.drawLine(leftLineBottom, rightLineBottom, _linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
