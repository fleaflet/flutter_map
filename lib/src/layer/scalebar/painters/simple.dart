part of '../scalebar.dart';

/// This is the [CustomPainter] that draws the scalebar label and lines
/// onto the canvas.
base class SimpleScalebarPainter extends ScalebarPainter {
  @protected
  @override
  late double scaleWidth;

  @protected
  @override
  late int scaleDistance;

  final double strokeWidth;
  final double lineHeight;
  final Color lineColor;

  final Paint _linePaint;

  /// Create a new [SimpleScalebarPainter], internally used in the [Scalebar].
  SimpleScalebarPainter({
    super.textGenerator,
    super.textStyle,
    super.padding,
    this.lineColor = const Color(0xFF000000),
    this.strokeWidth = 2,
    this.lineHeight = 5,
    // ignore: unnecessary_parenthesis
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
    final textSpan =
        TextSpan(style: textStyle, text: textGenerator(scaleDistance));
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    final x =
        scaleWidth / 2 - textPainter.width / 2 + paddingLeft + halfStrokeWidth;
    textPainter.paint(
      canvas,
      Offset(
        x < paddingLeft ? paddingLeft : x,
        paddingTop,
      ),
    );

    paddingTop += textPainter.height;
    final leftLineBottom = Offset(
      paddingLeft + halfStrokeWidth,
      lineHeight + paddingTop,
    );
    final rightLineBottom = Offset(
      paddingLeft + scaleWidth + halfStrokeWidth,
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
