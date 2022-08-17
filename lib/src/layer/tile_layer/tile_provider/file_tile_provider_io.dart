import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// [TileProvider] that uses [FileImage] internally on platforms other than web
class FileTileProvider extends TileProvider {
  FileTileProvider();

  @override
  ImageProvider getImage(Coords<num> coords, TileLayer options) {
    return FileImage(File(getTileUrl(coords, options)));
  }
}
