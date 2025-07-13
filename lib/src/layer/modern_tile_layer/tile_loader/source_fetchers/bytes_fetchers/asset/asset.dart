import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_source.dart';

/// A [SourceBytesFetcher] which fetches from the app's shipped assets, based on
/// their [TileSource]
///
/// In normal usage, all tiles (or at least each individual lowest-level
/// directory) must be listed as normal in the pubspec.
// TODO: This a considerably different implementation - check performance
@immutable
class AssetBytesFetcher implements SourceBytesFetcher<TileSource> {
  /// Asset bundle to retrieve tiles from
  final AssetBundle? assetBundle;

  /// A [SourceBytesFetcher] which fetches from the app's shipped assets, based
  /// on their [TileSource]
  ///
  /// By default, this uses the default [rootBundle]. If a different bundle is
  /// required, either specify it manually, or use the
  /// [AssetBytesFetcher.fromContext] constructor.
  const AssetBytesFetcher({this.assetBundle});

  /// A [SourceBytesFetcher] which fetches from the app's shipped assets, based
  /// on their [TileSource]
  ///
  /// Gets the asset bundle from the [DefaultAssetBundle] depending on the
  /// provided context.
  AssetBytesFetcher.fromContext(BuildContext context)
      : assetBundle = DefaultAssetBundle.of(context);

  @override
  Future<R> call<R>({
    required TileSource source,
    required Future<void> abortSignal,
    required BytesToResourceTransformer<R> transformer,
    bool useFallback = false,
  }) async {
    final bundle = assetBundle ?? rootBundle;
    final resolvedUri = useFallback ? source.fallbackUri ?? '' : source.uri;

    try {
      final bytes = await bundle.load(resolvedUri);
      return await transformer(Uint8List.sublistView(bytes));
    } on Exception {
      if (useFallback || source.fallbackUri == null) rethrow;
      return this(
        source: source,
        abortSignal: abortSignal,
        // In fallback scenarios, we never reuse bytes
        transformer: (bytes, {allowReuse = true}) =>
            transformer(bytes, allowReuse: false),
        useFallback: useFallback,
      );
    }
  }
}
