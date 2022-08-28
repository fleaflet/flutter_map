import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network_image_provider.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network_no_retry_image_provider.dart';

/// [TileProvider] that uses [FMNetworkImageProvider] internally
///
/// This image provider automatically retries some failed requests up to 3 times.
///
/// Note that this provider may be slower than [NetworkNoRetryTileProvider] when fetching tiles due to internal reasons.
///
/// Note that the 'User-Agent' header and the [RetryClient] cannot be changed, on the web platform.
class NetworkTileProvider extends TileProvider {
  NetworkTileProvider({
    Map<String, String>? headers,
    RetryClient? retryClient,
  }) {
    this.headers = headers ?? {};
    this.retryClient = retryClient ?? RetryClient(Client());
  }

  late final RetryClient retryClient;

  @override
  ImageProvider getImage(Coords<num> coords, TileLayer options) =>
      HttpOverrides.runZoned<FMNetworkImageProvider>(
        () => FMNetworkImageProvider(
          getTileUrl(coords, options),
          fallbackUrl: getTileFallbackUrl(coords, options),
          headers: headers,
          retryClient: retryClient,
        ),
        createHttpClient: (c) => _FlutterMapHTTPOverrides().createHttpClient(c),
      );
}

/// [TileProvider] that uses [FMNetworkNoRetryImageProvider] internally
///
/// This image provider does not automatically retry any failed requests. This provider is the default and the recommended provider, unless your tile server is especially unreliable.
///
/// Note that the 'User-Agent' header and the [HttpClient] cannot be changed, on the web platform.
class NetworkNoRetryTileProvider extends TileProvider {
  NetworkNoRetryTileProvider({
    Map<String, String>? headers,
    HttpClient? httpClient,
  }) {
    this.headers = headers ?? {};
    this.httpClient = httpClient ?? HttpClient()
      ..userAgent = null;
  }

  late final HttpClient httpClient;

  @override
  ImageProvider getImage(Coords<num> coords, TileLayer options) =>
      FMNetworkNoRetryImageProvider(
        getTileUrl(coords, options),
        fallbackUrl: getTileFallbackUrl(coords, options),
        headers: headers,
        httpClient: httpClient,
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

class _FlutterMapHTTPOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..userAgent = null;
  }
}
