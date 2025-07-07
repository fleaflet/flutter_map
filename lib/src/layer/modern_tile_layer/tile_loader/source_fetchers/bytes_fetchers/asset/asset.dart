import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_source.dart';

/// A tile bytes fetcher which fetches from the app's shipped assets, based on
/// their [TileSource]
///
/// In normal usage, all tiles (or at least each individual lowest-level
/// directory) must be listed as normal in the pubspec.
// TODO: This a considerably different implementation - check performance
// If adjustment is needed, it's likely to really mess up the contracts I've
// set up.
@immutable
class AssetBytesFetcher implements TileBytesFetcher<TileSource> {
  /// Asset bundle to retrieve tiles from
  final AssetBundle? assetBundle;

  /// A tile bytes fetcher which fetches from the app's shipped assets, based on
  /// their [TileSource]
  ///
  /// By default, this uses the default [rootBundle]. If a different bundle is
  /// required, either specify it manually, or use the
  /// [AssetBytesFetcher.fromContext] constructor.
  const AssetBytesFetcher({this.assetBundle});

  /// A tile bytes fetcher which fetches from the app's shipped assets, based on
  /// their [TileSource]
  ///
  /// Gets the asset bundle from the [DefaultAssetBundle] depending on the
  /// provided context.
  AssetBytesFetcher.fromContext(BuildContext context)
      : assetBundle = DefaultAssetBundle.of(context);

  @override
  Future<Uint8List> call(TileSource source, Future<void> abortSignal) async {
    final bundle = assetBundle ?? rootBundle;
    try {
      return Uint8List.sublistView(await bundle.load(source.uri));
    } on Exception {
      if (source.fallbackUri == null) rethrow;
      return Uint8List.sublistView(await bundle.load(source.fallbackUri!));
    }
  }
}
