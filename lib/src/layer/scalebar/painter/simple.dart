part of '../scalebar.dart';

/// This is the [CustomPainter] that draws the scalebar label and lines
/// onto the canvas.
class _SimpleScalebarPainter extends ScalebarPainter {
  static const _topPaddingCorr = -5.0;

  /// length of the scalebar
  final double scalebarLength;

  /// width of the scalebar line stroke
  final double strokeWidth;

  /// scalebar line height
  final double lineHeight;

  /// The alignment is used to align the scalebar if it is smaller than the
  /// text label.
  final Alignment alignment;

  /// The cached half of the line stroke width
  late final _halfStrokeWidth = strokeWidth / 2;
  late final _halfScalebarLength = scalebarLength / 2;
  late final _halfWidgetWidth = widgetSize.width / 2;

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
    // draw text label
    final labelX =
        widgetSize.width / 2 - _textPainter.width / 2 + _halfStrokeWidth;
    _textPainter.paint(
      canvas,
      Offset(max(0, labelX), _topPaddingCorr),
    );

    final paddingTop = _topPaddingCorr + _textPainter.height;
    final lineBottomY = lineHeight + paddingTop;
    final double lineLeftX;
    final double lineRightX;
    final double lineMiddleX;
    switch (alignment.x) {
      case -1: // aligned left
        lineLeftX = _halfStrokeWidth;
        lineRightX = lineLeftX + scalebarLength;
        lineMiddleX = lineLeftX + _halfScalebarLength;
      case 1: // aligned right
        lineRightX = widgetSize.width - _halfStrokeWidth;
        lineLeftX = lineRightX - scalebarLength;
        lineMiddleX = lineRightX - _halfScalebarLength;
      default: // aligned middle or custom
        lineMiddleX = _halfWidgetWidth;
        lineLeftX = lineMiddleX - _halfScalebarLength;
        lineRightX = lineMiddleX + _halfScalebarLength;
    }

    // 4 lines * 2 offsets * 2 coordinates
    final linePoints = Float32List.fromList(<double>[
      // left vertical line
      lineLeftX,
      paddingTop,
      lineLeftX,
      lineBottomY,
      // right vertical line
      lineRightX,
      paddingTop,
      lineRightX,
      lineBottomY,
      // middle vertical line
      lineMiddleX,
      paddingTop + lineHeight / 2,
      lineMiddleX,
      lineBottomY,
      // bottom horizontal line
      lineLeftX,
      lineBottomY,
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
