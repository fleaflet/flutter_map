import 'package:flutter/widgets.dart';
import 'package:http/retry.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network_image_provider.dart';

/// [TileProvider] that uses [FMNetworkImageProvider] internally
///
/// This image provider automatically retries some failed requests up to 3 times.
///
/// Note that this provider may be slower than [NetworkNoRetryTileProvider] when fetching tiles due to internal reasons.
///
/// Note that the 'User-Agent' header and the `RetryClient` cannot be changed, on the web platform.
class NetworkTileProvider extends TileProvider {
  NetworkTileProvider({
    Map<String, String>? headers,
  }) {
    this.headers = headers ?? {};
  }

  late final RetryClient retryClient;

  @override
  ImageProvider getImage(Coords<num> coords, TileLayer options) =>
      FMNetworkImageProvider(
        getTileUrl(coords, options),
        fallbackUrl: getTileFallbackUrl(coords, options),
        headers: headers..remove('User-Agent'),
      );
}

/// [TileProvider] that uses [NetworkImage] internally
///
/// This image provider does not automatically retry any failed requests. This provider is the default and the recommended provider, unless your tile server is especially unreliable.
///
/// Note that the 'User-Agent' header and the `HttpClient` cannot be changed, on the web platform.
class NetworkNoRetryTileProvider extends TileProvider {
  NetworkNoRetryTileProvider({
    Map<String, String>? headers,
  }) {
    this.headers = headers ?? {};
  }

  @override
  ImageProvider getImage(Coords<num> coords, TileLayer options) => NetworkImage(
        getTileUrl(coords, options),
        headers: headers..remove('User-Agent'),
      );
}

/// A very basic [TileProvider] implementation, that can be extended to create your own provider
///
/// Using this method is not recommended any more, except for very simple custom [TileProvider]s. Instead, visit the online documentation at https://docs.fleaflet.dev/plugins/making-a-plugin/creating-new-tile-providers.
class CustomTileProvider extends TileProvider {
  final String Function(Coords coors, TileLayer options) customTileUrl;

  CustomTileProvider({required this.customTileUrl});

  @override
  String getTileUrl(Coords coords, TileLayer options) {
    return customTileUrl(coords, options);
  }

  @override
  ImageProvider getImage(Coords<num> coords, TileLayer options) {
    return AssetImage(getTileUrl(coords, options));
  }
}
