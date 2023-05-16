import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network_image_provider.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

/// [TileProvider] to fetch tiles from the network
///
/// By default, a [RetryClient] is used to retry failed requests. 'dart:http'
/// or 'dart:io' might be needed to override this.
///
/// On the web, the 'User-Agent' header cannot be changed as specified in
/// [TileLayer.tileProvider]'s documentation, due to a Dart/browser limitation.
class NetworkTileProvider extends TileProvider {
  /// [TileProvider] to fetch tiles from the network
  ///
  /// By default, a [RetryClient] is used to retry failed requests. 'dart:http'
  /// or 'dart:io' might be needed to override this.
  ///
  /// On the web, the 'User-Agent' header cannot be changed as specified in
  /// [TileLayer.tileProvider]'s documentation, due to a Dart/browser limitation.
  NetworkTileProvider({
    super.headers = const {},
    BaseClient? httpClient,
  }) : httpClient = httpClient ?? RetryClient(Client());

  /// The HTTP client used to make network requests for tiles
  final BaseClient httpClient;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      FlutterMapNetworkImageProvider(
        url: getTileUrl(coordinates, options),
        fallbackUrl: getTileFallbackUrl(coordinates, options),
        headers: headers,
        httpClient: httpClient,
      );
}
