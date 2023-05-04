import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/base_tile_provider.dart';

/// [TileProvider] that uses [NetworkImage] internally on the web
///
/// Note that this is not recommended, as important headers cannot be passed.
/// Use [NetworkNoRetryTileProvider] if you know the platform is the web.
class FileTileProvider extends TileProvider {
  FileTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return NetworkImage(getTileUrl(coordinates, options));
  }
}
