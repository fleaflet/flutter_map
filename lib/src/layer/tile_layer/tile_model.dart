import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_builder.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image.dart';

/// The widget for a single tile used for the [TileLayer].
/// This replaces the `Tile` widget in the `flutter_map` package making it deprecated.
/// Previously the `Tile` widget was a `StatefulWidget`. That is not needed with rendering tiles in Canvas.
class TileModel {
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

  /// The key for the tile.
  /// I think this is needed to keep track of the tiles and prune them when they are not needed.
  final ObjectKey key;

  /// Creates a new instance of [Tile].
  const TileModel(
      {required this.scaledTileSize,
      required this.currentPixelOrigin,
      required this.tileImage,
      required this.tileBuilder,
      required this.key});
}
