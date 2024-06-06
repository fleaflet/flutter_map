import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_painter.dart';

/// Model for tiles displayed by [TileLayer] and [TilePainter]
class TileModel {
  /// [TileImage] is the model class that contains meta data for the Tile image.
  final TileImage tileImage;

  /// The tile size for the given scale of the map.
  final double scaledTileSize;

  /// Reference to the offset of the top-left corner of the bounding rectangle
  /// of the [MapCamera]. The origin will not equal the offset of the top-left
  /// visible pixel when the map is rotated.
  final Point<double> currentPixelOrigin;

  /// Creates a new instance of TileModel.
  const TileModel({
    required this.scaledTileSize,
    required this.currentPixelOrigin,
    required this.tileImage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TileModel &&
          tileImage == other.tileImage &&
          scaledTileSize == other.scaledTileSize &&
          currentPixelOrigin == other.currentPixelOrigin);

  @override
  int get hashCode =>
      Object.hash(tileImage, scaledTileSize, currentPixelOrigin);
}
