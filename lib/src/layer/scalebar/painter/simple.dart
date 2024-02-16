part of '../scalebar.dart';

/// This is the [CustomPainter] that draws the scalebar label and lines
/// onto the canvas.
class _SimpleScalebarPainter extends ScalebarPainter {
  static const _topPaddingCorr = -5.0;
  final double scalebarLength;
  final String label;
  final double strokeWidth;
  final double lineHeight;
  final TextStyle? textStyle;

  final Paint _linePaint = Paint();
  final TextPainter _textPainter;

  /// Create a new [Scalebar], internally used in the [Scalebar].
  _SimpleScalebarPainter({
    required this.scalebarLength,
    required this.label,
    required this.textStyle,
    required this.strokeWidth,
    required this.lineHeight,
    required Color lineColor,
  }) : _textPainter = TextPainter(
          text: TextSpan(style: textStyle, text: label),
          textDirection: TextDirection.ltr,
        ) {
    _linePaint
      ..color = lineColor
      ..strokeCap = StrokeCap.square
      ..strokeWidth = strokeWidth;
    _textPainter.layout();
  }

  @override
  Size get widgetSize => Size(
        scalebarLength + strokeWidth,
        _textPainter.height + _topPaddingCorr + lineHeight,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final halfStrokeWidth = strokeWidth / 2;

    // draw text label
    final labelX =
        scalebarLength / 2 - _textPainter.width / 2 + halfStrokeWidth;
    _textPainter.paint(canvas, Offset(max(0, labelX), _topPaddingCorr));

    final paddingTop = _topPaddingCorr + _textPainter.height;
    final leftLineBottom = Offset(
      halfStrokeWidth,
      lineHeight + paddingTop,
    );
    final rightLineBottom = Offset(
      scalebarLength + halfStrokeWidth,
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
