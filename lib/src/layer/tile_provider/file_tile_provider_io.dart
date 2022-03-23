import 'dart:io';

import 'package:flutter/widgets.dart';

import '../tile_layer.dart';
import 'tile_provider.dart';

/// FileTileProvider
class FileTileProvider extends TileProvider {
  const FileTileProvider();
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return FileImage(File(getTileUrl(coords, options)));
  }
}
