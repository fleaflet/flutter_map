import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_model.dart';

/// Draws [TileModel]s onto a canvas at the correct position
class TilePainter extends CustomPainter {
  /// List of [TileModel]s to draw to the canvas
  List<TileModel> tiles;

  /// Paint to use when drawing each tile
  ///
  /// Defaults to [defaultTilePaint].
  final Paint? tilePaint;

  /// Default [tilePaint]er
  static Paint get defaultTilePaint => Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.high;

  /// Create a painter with the specified [TileModel]s and paint
  ///
  /// [tilePaint] indirectly defaults to [defaultTilePaint].
  TilePainter({
    required this.tiles,
    this.tilePaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final tile in tiles) {
      // Draw tiles if they have an image
      if (tile.tileImage.imageInfo != null) {
        // Simplify tile positions and sizes
        final left = tile.tileImage.coordinates.x * tile.scaledTileSize -
            tile.currentPixelOrigin.x;
        final top = tile.tileImage.coordinates.y * tile.scaledTileSize -
            tile.currentPixelOrigin.y;
        final width = tile.scaledTileSize;
        final height = tile.scaledTileSize;
        final image = tile.tileImage.imageInfo!.image;

        canvas.drawImageRect(
          image,
          // Source rectangle
          Rect.fromLTWH(
            0,
            0,
            image.width.toDouble(),
            image.height.toDouble(),
          ),
          Rect.fromLTWH(left, top, width, height), // Destination rectangle
          (tilePaint ?? defaultTilePaint)..color = 
          (tilePaint ?? defaultTilePaint).color.withOpacity(tile.tileImage.opacity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TilePainter oldDelegate) {
    return oldDelegate.tiles != tiles;
  }
}
