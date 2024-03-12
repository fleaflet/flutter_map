import 'package:flutter/material.dart';

import 'package:flutter_map/src/layer/tile_layer/placeholder/tile_placeholder_painter.dart';

/// A placeholder widget for unloaded tile images.
class TilePlaceholder extends StatelessWidget {
  /// A placeholder widget for unloaded tile images.
  const TilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const LimitedBox(
      maxWidth: 400,
      maxHeight: 400,
      child: CustomPaint(
        size: Size.infinite,
        painter: TilePlaceholderPainter(
          color: Colors.white,
          strokeWidth: 1,
        ),
      ),
    );
  }
}
