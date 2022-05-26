import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/coords.dart';

/// FileTileProvider

class FileTileProvider extends TileProvider {
  const FileTileProvider();
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return NetworkImage(getTileUrl(coords, options));
  }
}
