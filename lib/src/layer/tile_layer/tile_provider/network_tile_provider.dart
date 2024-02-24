import 'dart:async';
import 'dart:collection';

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
    this.silenceExceptions = false,
  }) : _httpClient = httpClient ?? RetryClient(Client());

  /// Whether to ignore exceptions and errors that occur whilst fetching tiles
  /// over the network, and just return a transparent tile
  final bool silenceExceptions;

  /// Long living client used to make all tile requests by
  /// [MapNetworkImageProvider] for the duration that this provider is
  /// alive
  final BaseClient _httpClient;

  /// Each [Completer] is completed once the corresponding tile has finished
  /// loading
  ///
  /// Used to avoid disposing of [_httpClient] whilst HTTP requests are still
  /// underway.
  ///
  /// Does not include tiles loaded from session cache.
  final _tilesInProgress = HashMap<TileCoordinates, Completer<void>>();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MapNetworkImageProvider(
        url: getTileUrl(coordinates, options),
        fallbackUrl: getTileFallbackUrl(coordinates, options),
        headers: headers,
        httpClient: _httpClient,
        silenceExceptions: silenceExceptions,
        startedLoading: () => _tilesInProgress[coordinates] = Completer(),
        finishedLoadingBytes: () {
          _tilesInProgress[coordinates]?.complete();
          _tilesInProgress.remove(coordinates);
        },
      );

  @override
  Future<void> dispose() async {
    if (_tilesInProgress.isNotEmpty) {
      await Future.wait(_tilesInProgress.values.map((c) => c.future));
    }
    _httpClient.close();
    super.dispose();
  }
}
