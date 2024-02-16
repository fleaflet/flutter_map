part of '../scalebar.dart';

/// This is the [CustomPainter] that draws the scalebar label and lines
/// onto the canvas.
class _SimpleScalebarPainter extends ScalebarPainter {
  static const _topPaddingCorr = -5.0;
  final double scalebarLength;
  final double strokeWidth;
  final double lineHeight;

  /// The alignment is used to align the scalebar if it is smaller than the
  /// text label.
  final Alignment alignment;

  final Paint _linePaint = Paint();
  final TextPainter _textPainter;

  @override
  late final Size widgetSize = Size(
    max(scalebarLength + strokeWidth, _textPainter.width),
    _textPainter.height + _topPaddingCorr + lineHeight,
  );

  /// Create a new [Scalebar], internally used in the [Scalebar].
  _SimpleScalebarPainter({
    required this.scalebarLength,
    required TextSpan text,
    required this.strokeWidth,
    required this.lineHeight,
    required Color lineColor,
    required this.alignment,
  }) : _textPainter = TextPainter(
          text: text,
          textDirection: TextDirection.ltr,
          maxLines: 1,
        ) {
    _linePaint
      ..color = lineColor
      ..strokeCap = StrokeCap.square
      ..strokeWidth = strokeWidth;
    _textPainter.layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final halfStrokeWidth = strokeWidth / 2;

    // draw text label
    final labelX =
        widgetSize.width / 2 - _textPainter.width / 2 + halfStrokeWidth;
    _textPainter.paint(
      canvas,
      Offset(max(0, labelX), _topPaddingCorr),
    );

    final paddingTop = _topPaddingCorr + _textPainter.height;
    final lineBottomY = lineHeight + paddingTop;
    final lineRightX = scalebarLength + halfStrokeWidth;
    final lineMiddleX = halfStrokeWidth + lineRightX / 2;

    // 4 lines * 2 offsets * 2 coordinates
    final linePoints = Float32List.fromList(<double>[
      // left vertical line
      halfStrokeWidth,
      paddingTop,
      halfStrokeWidth,
      lineHeight + paddingTop,
      // right vertical line
      lineRightX,
      paddingTop,
      lineRightX,
      lineBottomY,
      // middle vertical line
      lineMiddleX,
      paddingTop + lineHeight / 2,
      lineMiddleX,
      lineHeight + paddingTop,
      // bottom horizontal line
      halfStrokeWidth,
      lineHeight + paddingTop,
      lineRightX,
      lineBottomY,
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
