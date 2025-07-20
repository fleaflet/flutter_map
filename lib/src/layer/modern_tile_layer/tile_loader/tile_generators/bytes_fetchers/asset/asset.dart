import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_generators/bytes_fetchers/bytes_fetcher.dart';

/// A [SourceBytesFetcher] which fetches a URI from the app's shipped assets.
///
/// {@macro fm.sbf.default.sourceConsumption}
///
/// In normal usage, all tiles (or at least each individual lowest-level
/// directory) must be listed as normal in the pubspec.
// TODO: This a considerably different implementation - check performance
@immutable
class AssetBytesFetcher implements SourceBytesFetcher<Iterable<String>> {
  /// Asset bundle to retrieve tiles from.
  final AssetBundle? assetBundle;

  /// A [SourceBytesFetcher] which fetches from the app's shipped assets.
  ///
  /// By default, this uses the default [rootBundle]. If a different bundle is
  /// required, either specify it manually, or use the
  /// [AssetBytesFetcher.fromContext] constructor.
  const AssetBytesFetcher({this.assetBundle});

  /// A [SourceBytesFetcher] which fetches from the app's shipped assets.
  ///
  /// Gets the asset bundle from the [DefaultAssetBundle] depending on the
  /// provided context.
  AssetBytesFetcher.fromContext(BuildContext context)
      : assetBundle = DefaultAssetBundle.of(context);

  @override
  Future<R> call<R>({
    required Iterable<String> source,
    required Future<void> abortSignal,
    required BytesToResourceTransformer<R> transformer,
  }) {
    final bundle = assetBundle ?? rootBundle;
    return fetchFromSourceIterable(
      (uri, transformer, isFirst) =>
          bundle.load(uri).then(Uint8List.sublistView).then(transformer),
      source: source,
      transformer: transformer,
    );
  }
}
