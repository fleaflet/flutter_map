import 'package:flutter/material.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_image.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';

/// A callback that can draw directly on the canvas, over a tile
///
/// See [TileLayer.tileOverlayPainter] for more information.
typedef TileOverlayPainter = void Function({
  required Canvas canvas,
  required Offset origin,
  required Size size,
  required TileImage tile,
})?;
