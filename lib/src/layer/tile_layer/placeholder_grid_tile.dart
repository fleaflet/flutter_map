import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class PlaceholderGridTile extends StatelessWidget {
  final int cellCount;
  final Color lineColor;
  final Color? backgroundColor;

  /// Creates a placeholder tile which is a grid with [cellCount] cells on both
  /// axis. The cells are have a background of [backgroundColor] (default
  /// transparent) and are divided by lines with the color [lineColor].
  const PlaceholderGridTile({
    super.key,
    this.cellCount = 8,
    this.lineColor = Colors.white,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PlaceholderGridTilePainter(
        lineColor: lineColor,
        cellCount: cellCount,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

class _PlaceholderGridTilePainter extends CustomPainter {
  final int cellCount;
  final Color lineColor;
  final Color? backgroundColor;

  _PlaceholderGridTilePainter({
    required this.cellCount,
    required this.lineColor,
    required this.backgroundColor,
  });

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = Paint();
    if (backgroundColor != null && backgroundColor != Colors.transparent) {
      paint
        ..color = backgroundColor!
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, paint);
    }

    paint
      ..color = lineColor
      ..style = PaintingStyle.stroke;

    final tileSize = size.width;
    final cellOffsetSize = tileSize / cellCount;

    // Draw lines
    for (int i = 0; i <= cellCount; i++) {
      if (i % cellCount == 0) {
        paint.strokeWidth = 1;
      } else {
        paint.strokeWidth = 0.5;
      }
      final cellOffset = cellOffsetSize * i;
      // Horizontal line.
      canvas.drawLine(
        Offset(0, cellOffset),
        Offset(tileSize, cellOffset),
        paint,
      );
      // Vertical line.
      canvas.drawLine(
        Offset(cellOffset, 0),
        Offset(cellOffset, tileSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PlaceholderGridTilePainter oldDelegate) =>
      lineColor != oldDelegate.lineColor ||
      cellCount != oldDelegate.cellCount ||
      backgroundColor != oldDelegate.backgroundColor;
}
