import 'package:flutter/material.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_model.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_overlay_painter.dart';
import 'package:meta/meta.dart';

/// Draws [TileModel]s onto a canvas at the correct position
@internal
class TilePainter extends CustomPainter {
  final List<TileModel> tiles;
  final Paint? tilePaint;
  final TileOverlayPainter tileOverlayPainter;
  final Paint _basePaint;

  TilePainter({
    required this.tiles,
    required this.tilePaint,
    required this.tileOverlayPainter,
  })  : _basePaint = (tilePaint ?? Paint())
          ..filterQuality = FilterQuality.high
          ..isAntiAlias = true,
        super(
          repaint: Listenable.merge(tiles
              .map<Listenable?>((t) => t.tileImage.animation)
              .followedBy(tiles.map((t) => t.tileImage))),
        );

  @override
  void paint(Canvas canvas, Size size) {
    for (final tile in tiles) {
      if (tile.tileImage.imageInfo != null) {
        final image = tile.tileImage.imageInfo!.image;

        final origin = Offset(
          tile.tileImage.coordinates.x * tile.scaledTileSize -
              tile.currentPixelOrigin.x,
          tile.tileImage.coordinates.y * tile.scaledTileSize -
              tile.currentPixelOrigin.y,
        );
        final destSize = Size.square(tile.scaledTileSize);

        final paint = _basePaint
          ..color = (tilePaint?.color.withOpacity(tile.tileImage.opacity) ??
              Color.fromRGBO(0, 0, 0, tile.tileImage.opacity));

        canvas.drawImageRect(
          image,
          Offset.zero &
              Size(image.width.toDouble(), image.height.toDouble()), // src
          origin & destSize, // dest
          paint,
        );

        tileOverlayPainter?.call(
          canvas: canvas,
          origin: origin,
          size: destSize,
          tile: tile.tileImage,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TilePainter oldDelegate) => true;
}
