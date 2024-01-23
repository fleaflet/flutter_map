import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';

import 'test_tile_image.dart';

class TestTileProvider extends TileProvider {
  @override
  ImageProvider<Object> getImage(
          TileCoordinates coordinates, TileLayer options) =>
      testWhiteTileImage;
}
