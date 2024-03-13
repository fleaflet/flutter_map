import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_model.dart';

///Draws the tile images on the canvas.
class TilePainter extends CustomPainter {
  /// The list of tile models.
  List<TileModel> tiles;

  ///Allows user to pass a custom paint object to the canvas.
  final Paint? tilePaint;

  /// Constructs a `TilePainter` with the given list of `TileModel` objects.
  TilePainter({required this.tiles, this.tilePaint});

  /// The default paint object.
  Paint get _defaultPaint => Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.high;

  @override
  void paint(Canvas canvas, Size size) {
    for (final tile in tiles) {
      //Draw tiles if they have an image
      if (tile.tileImage.imageInfo != null) {
        //Simplify tile positions and sizes
        final double left = tile.tileImage.coordinates.x * tile.scaledTileSize -
            tile.currentPixelOrigin.x;
        final double top = tile.tileImage.coordinates.y * tile.scaledTileSize -
            tile.currentPixelOrigin.y;
        final double width = tile.scaledTileSize;
        final double height = tile.scaledTileSize;
        final ui.Image image = tile.tileImage.imageInfo!.image;
        final Paint paint = tilePaint ?? _defaultPaint;
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(),
              image.height.toDouble()), // Source rectangle
          Rect.fromLTWH(left, top, width, height), // Destination rectangle
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TilePainter oldDelegate) {
    return oldDelegate.tiles != tiles;
  }
}
