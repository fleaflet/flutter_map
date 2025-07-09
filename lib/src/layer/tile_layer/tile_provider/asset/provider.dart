import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';

/// Fetch tiles from the app's shipped assets, where the tile URL is a path
/// within the asset store
///
/// Uses [AssetImage] internally.
///
/// All tiles must be listed as assets as normal in the pubspec.yaml config file.
///
/// If [TileLayer.fallbackUrl] is specified, a custom [CachingAssetBundle] is
/// used to retrieve the assets - this bundle is approximatley 23% slower than
/// the default bundle, and as such, specifying [TileLayer.fallbackUrl] should be
/// avoided when using this provider.
class AssetTileProvider extends TileProvider {
  @override
  AssetImage getImage(TileCoordinates coordinates, TileLayer options) {
    final fallbackUrl = getTileFallbackUrl(coordinates, options);
    return AssetImage(
      getTileUrl(coordinates, options),
      bundle: fallbackUrl == null
          ? null
          : _FlutterMapAssetBundle(fallbackUrl: fallbackUrl),
    );
  }
}

@immutable
class _FlutterMapAssetBundle extends CachingAssetBundle {
  _FlutterMapAssetBundle({required this.fallbackUrl});

  final String fallbackUrl;

  Future<ByteData?> _loadAsset(String key) async {
    final encoded = utf8.encoder.convert(Uri(path: Uri.encodeFull(key)).path);
    final asset = await ServicesBinding.instance.defaultBinaryMessenger
        .send('flutter/assets', encoded.buffer.asByteData());
    return asset;
  }

  @override
  Future<ByteData> load(String key) async {
    final asset = await _loadAsset(key);
    if (asset != null && asset.lengthInBytes > 0) return asset;

    final fallbackAsset = await _loadAsset(fallbackUrl);
    if (fallbackAsset != null) return fallbackAsset;

    throw FlutterError('_FlutterMapAssetBundle - Unable to load asset: $key');
  }
}
