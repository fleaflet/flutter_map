import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class TilePlaceholder extends StatelessWidget {
  final TileCoordinates tileCoordinates;
  final double scaledTileSize;
  final Point<double> currentPixelOrigin;
  final ImageProvider placeholderImage;

  const TilePlaceholder({
    super.key,
    required this.tileCoordinates,
    required this.scaledTileSize,
    required this.currentPixelOrigin,
    required this.placeholderImage,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: tileCoordinates.x * scaledTileSize - currentPixelOrigin.x,
      top: tileCoordinates.y * scaledTileSize - currentPixelOrigin.y,
      width: scaledTileSize,
      height: scaledTileSize,
      child: Image(
        width: scaledTileSize,
        height: scaledTileSize,
        image: placeholderImage,
        fit: BoxFit.fill,
      ),
    );
  }
}
