import 'dart:math';

import 'package:flutter/material.dart';

class Label {
  static void paintText(
    Canvas canvas,
    List<Offset> points,
    String? labelText,
    TextStyle? labelStyle,
  ) {
    var maxDx = 0.0;
    var minDx = double.infinity;
    var dx = points.map((e) => e.dx).toList().fold<double>(0.0,
            (previousValue, element) {
          maxDx = max(maxDx, element);
          minDx = min(minDx, element);
          return previousValue + element;
        }) /
        points.length;
    var dy = points.map((e) => e.dy).toList().fold<double>(
            0.0, (previousValue, element) => previousValue + element) /
        points.length;

    final textSpan = TextSpan(text: labelText, style: labelStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    if (dx > 0) {
      textPainter.layout(minWidth: 0, maxWidth: double.infinity);
      dx = dx - textPainter.width / 2;
      dy = dy - textPainter.height / 2;

      if (maxDx - minDx > textPainter.width) {
        textPainter.paint(
          canvas,
          Offset(dx, dy),
        );
      }
    }
  }
}
