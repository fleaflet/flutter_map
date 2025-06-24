import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/image_provider/image_provider.dart';
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
    Client? httpClient,
    this.silenceExceptions = false,
    this.attemptDecodeOfHttpErrorResponses = true,
    this.cachingProvider,
  })  : _isInternallyCreatedClient = httpClient == null,
        _httpClient = httpClient ?? RetryClient(Client());

  /// Whether to ignore exceptions and errors that occur whilst fetching tiles
  /// over the network, and just return a transparent tile
  ///
  /// Defaults to `false`.
  final bool silenceExceptions;

  /// Whether to optimistically attempt to decode HTTP responses that have a
  /// non-successful status code as an image
  ///
  /// If the decode is unsuccessful, the behaviour depends on
  /// [silenceExceptions].
  ///
  /// Defaults to `true`.
  final bool attemptDecodeOfHttpErrorResponses;

  /// Caching provider used to get cached tiles
  ///
  /// See online documentation for more information about built-in caching.
  ///
  /// Defaults to [BuiltInMapCachingProvider]. Set to
  /// [DisabledMapCachingProvider] to disable.
  final MapCachingProvider? cachingProvider;

  /// Long living client used to make all tile requests by
  /// [NetworkTileImageProvider] for the duration that this provider is
  /// alive
  ///
  /// Not automatically closed if created externally and passed as an argument
  /// during construction.
  final Client _httpClient;

  /// Whether [_httpClient] was created on construction (and not passed in)
  final bool _isInternallyCreatedClient;

  @override
  bool get supportsCancelLoading => false;

  @override
  ImageProvider<Object> getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) =>
      NetworkTileImageProvider(
        url: getTileUrl(coordinates, options),
        fallbackUrl: getTileFallbackUrl(coordinates, options),
        headers: headers,
        httpClient: _httpClient,
        abortTrigger: null,
        silenceExceptions: silenceExceptions,
        attemptDecodeOfHttpErrorResponses: attemptDecodeOfHttpErrorResponses,
        cachingProvider: cachingProvider,
      );

  @override
  Future<void> dispose() async {
    if (_isInternallyCreatedClient) _httpClient.close();
    super.dispose();
  }
}
