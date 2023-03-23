import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinate.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/base_tile_provider.dart';

/// [TileProvider] that uses [FileImage] internally on platforms other than web
class FileTileProvider extends TileProvider {
  FileTileProvider();

  @override
  ImageProvider getImage(TileCoordinate coords, TileLayer options) {
    return FileImage(File(getTileUrl(coords, options)));
  }
}
