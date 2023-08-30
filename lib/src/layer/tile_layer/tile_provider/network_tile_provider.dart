import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/base_tile_provider.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network_image_provider.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:logger/logger.dart';

/// [TileProvider] to fetch tiles from the network
///
/// By default, a [RetryClient] is used to retry failed requests. 'dart:http'
/// or 'dart:io' might be needed to override this.
///
/// On the web, the 'User-Agent' header cannot be changed as specified in
/// [TileLayer.tileProvider]'s documentation, due to a Dart/browser limitation.
///
/// Does not support cancellation of tile loading via
/// [TileProvider.getImageWithCancelLoadingSupport], as abortion of in-flight
/// HTTP requests on the web is
/// [not yet supported in Dart](https://github.com/dart-lang/http/issues/424).
class NetworkTileProvider extends TileProvider {
  /// [TileProvider] to fetch tiles from the network
  ///
  /// By default, a [RetryClient] is used to retry failed requests. 'dart:http'
  /// or 'dart:io' might be needed to override this.
  ///
  /// On the web, the 'User-Agent' header cannot be changed, as specified in
  /// [TileLayer.tileProvider]'s documentation, due to a Dart/browser limitation.
  ///
  /// Does not support cancellation of tile loading via
  /// [TileProvider.getImageWithCancelLoadingSupport], as abortion of in-flight
  /// HTTP requests on the web is
  /// [not yet supported in Dart](https://github.com/dart-lang/http/issues/424).
  NetworkTileProvider({
    super.headers,
    BaseClient? httpClient,
  }) : httpClient = httpClient ?? RetryClient(Client()) {
    if (kDebugMode) {
      Logger(printer: PrettyPrinter(methodCount: 0)).i(
        '\x1B[1m\x1B[3mflutter_map\x1B[0m\nConsider installing the official '
        "'flutter_map_cancellable_tile_provider' plugin for improved\n"
        'performance on the web.\nSee '
        'https://pub.dev/packages/flutter_map_cancellable_tile_provider for '
        'more info.',
      );
    }
  }

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

  @override
  void dispose() {
    httpClient.close();
    super.dispose();
  }
}
