import 'package:flutter/widgets.dart';

import '../tile_layer.dart';
import 'tile_provider.dart';

class FileTileProvider extends TileProvider {
  const FileTileProvider();
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return NetworkImage(getTileUrl(coords, options));
  }
}
