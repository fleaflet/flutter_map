import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/independent/image_provider.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/web/tile_loader.dart';
import 'package:meta/meta.dart';

@internal
Future<Codec> loadTileImage(
  NetworkTileImageProvider key,
  ImageDecoderCallback decode, {
  bool useFallback = false,
}) =>
    simpleLoadTileImage(key, decode, useFallback: useFallback);
