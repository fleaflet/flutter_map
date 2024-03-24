import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_painter.dart';

/// Model for tiles displayed by [TileLayer] and [TilePainter]
class TileModel {
  /// Controls how this tile is replaced by another tile
  ///
  /// See also:
  ///
  ///  * [Widget.key]
  ///  * The discussions at [Key] and [GlobalKey].
  final ObjectKey key;

  /// [TileImage] is the model class that contains meta data for the Tile image.
  final TileImage tileImage;

  /// The [TileBuilder] is a reference to the [TileLayer]'s
  /// [TileLayer.tileBuilder].
  final TileBuilder? tileBuilder;

  /// The tile size for the given scale of the map.
  final double scaledTileSize;

  /// Reference to the offset of the top-left corner of the bounding rectangle
  /// of the [MapCamera]. The origin will not equal the offset of the top-left
  /// visible pixel when the map is rotated.
  final Point<double> currentPixelOrigin;

  /// Creates a new instance of TileModel.
  const TileModel({
    required this.key,
    required this.scaledTileSize,
    required this.currentPixelOrigin,
    required this.tileImage,
    required this.tileBuilder,
  });
}
