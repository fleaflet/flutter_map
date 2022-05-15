import 'package:flutter/widgets.dart';

import 'package:flutter_map/src/layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_provider/tile_provider.dart';

/// FileTileProvider

class FileTileProvider extends TileProvider {
  const FileTileProvider();
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return NetworkImage(getTileUrl(coords, options));
  }
}
