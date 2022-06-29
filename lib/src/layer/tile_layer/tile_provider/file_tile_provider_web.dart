import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// [TileProvider] that uses [NetworkImage] internally on the web
///
/// Note that this is not recommended, as important headers cannot be passed.
/// Use [NetworkNoRetryTileProvider] if you know the platform is the web.
class FileTileProvider extends TileProvider {
  FileTileProvider();

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return NetworkImage(getTileUrl(coords, options));
  }
}
