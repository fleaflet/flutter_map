import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class PositionedTile extends StatelessWidget {
  final TileCoordinates tileCoordinates;
  final double scaledTileSize;
  final Point<double> currentPixelOrigin;
  final Widget child;

  const PositionedTile({
    super.key,
    required this.tileCoordinates,
    required this.scaledTileSize,
    required this.currentPixelOrigin,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: tileCoordinates.x * scaledTileSize - currentPixelOrigin.x,
      top: tileCoordinates.y * scaledTileSize - currentPixelOrigin.y,
      width: scaledTileSize,
      height: scaledTileSize,
      child: child,
    );
  }
}
