import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/base_tile_provider.dart';

/// [TileProvider] to fetch tiles from the local filesystem (not asset store)
///
/// Uses [FileImage] internally.
class FileTileProvider extends TileProvider {
  /// [TileProvider] to fetch tiles from the local filesystem (not asset store)
  ///
  /// Uses [FileImage] internally.
  FileTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      FileImage(File(getTileUrl(coordinates, options)));
}
