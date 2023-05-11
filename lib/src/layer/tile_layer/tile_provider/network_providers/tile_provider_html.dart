import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/base_tile_provider.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network_providers/image_provider.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network_providers/tile_provider_base.dart';

import 'package:http/retry.dart';

/// [TileProvider] to fetch tiles from the network
///
/// By default, a [RetryClient] is used to retry failed requests.
///
/// This web implmentation does not support changing the 'User-Agent' header, due
/// to a Dart/browser limitation.
class NetworkTileProvider extends NetworkTileProviderBase {
  /// [TileProvider] to fetch tiles from the network
  ///
  /// By default, a [RetryClient] is used to retry failed requests.
  ///
  /// This web implmentation does not support changing the 'User-Agent' header,
  /// due to a Dart/browser limitation.
  NetworkTileProvider({
    super.headers = const {},
    super.httpClient,
  });

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      FlutterMapNetworkImageProvider(
        url: getTileUrl(coordinates, options),
        fallbackUrl: getTileFallbackUrl(coordinates, options),
        headers: headers,
        httpClient: httpClient,
      );
}
