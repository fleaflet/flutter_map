import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/base_tile_provider.dart';

class AssetTileProvider extends TileProvider {
  @override
  AssetImage getImage(TileCoordinates coordinates, TileLayer options) {
    return AssetImage(
      getTileUrl(coordinates, options),
      bundle: _FlutterMapAssetBundle(
        fallbackKey: getTileFallbackUrl(coordinates, options),
      ),
    );
  }
}

/// Used to load a fallback asset when the main asset is not found.
class _FlutterMapAssetBundle extends CachingAssetBundle {
  final String? fallbackKey;

  _FlutterMapAssetBundle({required this.fallbackKey});

  Future<ByteData?> _loadAsset(String key) async {
    final Uint8List encoded =
        utf8.encoder.convert(Uri(path: Uri.encodeFull(key)).path);
    final ByteData? asset = await ServicesBinding
        .instance.defaultBinaryMessenger
        .send('flutter/assets', encoded.buffer.asByteData());
    return asset;
  }

  @override
  Future<ByteData> load(String key) async {
    final asset = await _loadAsset(key);
    if (asset != null && asset.lengthInBytes > 0) return asset;

    if (fallbackKey != null) {
      final fallbackAsset = await _loadAsset(fallbackKey!);
      if (fallbackAsset != null) return fallbackAsset;
    }

    throw FlutterError('_FlutterMapAssetBundle - Unable to load asset: $key');
  }
}
