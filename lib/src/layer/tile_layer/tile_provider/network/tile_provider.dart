import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/image_provider/image_provider.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

/// [TileProvider] to fetch tiles from the network.
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
  /// [TileProvider] to fetch tiles from the network.
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
    this.abortObsoleteRequests = true,
    this.cachingProvider,
  })  : _isInternallyCreatedClient = httpClient == null,
        _httpClient = httpClient ?? RetryClient(Client());

  /// Whether to ignore exceptions and errors that occur whilst fetching tiles
  /// over the network, and just return a transparent tile.
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

  /// Whether to abort HTTP requests for tiles that will no longer be displayed.
  ///
  /// For example, tiles may be pruned from an intermediate zoom level during a
  /// user's fast zoom. When disabled, the request for each tile that has been
  /// pruned still needs to complete and be processed. When enabled, those
  /// tiles' requests can be aborted before they are fully loaded.
  ///
  /// > [!TIP]
  /// > This functionality replaces the 'flutter_map_cancellable_tile_provider'
  /// > plugin package.
  ///
  /// This may have multiple advantages:
  ///  * It may improve tile loading speeds
  ///  * It may reduce the user's consumption of a metered network connection
  ///  * It may reduce the user's consumption of storage capacity in the
  ///    [cachingProvider]
  ///  * It may reduce unnecessary tile requests, reducing tile server costs
  ///  * It may negligibly improve app performance in general
  ///
  /// This is likely to be more effective on web platforms (where
  /// `BrowserClient` is used) and with clients or servers with limited numbers
  /// of simultaneous connections or slow traffic speeds, but is also likely to
  /// have a positive effect everywhere. If an HTTP client is used which does
  /// not support the standard method of request aborting, this has no effect.
  ///
  /// Defaults to `true`. It is recommended to enable this functionality, unless
  /// you suspect it is causing problems; in this case, please report the issue
  /// to flutter_map.
  final bool abortObsoleteRequests;

  /// Caching provider used to get cached tiles.
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
  bool get supportsCancelLoading => true;

  @override
  ImageProvider getImageWithCancelLoadingSupport(
    TileCoordinates coordinates,
    TileLayer options,
    Future<void> cancelLoading,
  ) =>
      NetworkTileImageProvider(
        url: getTileUrl(coordinates, options),
        fallbackUrl: getTileFallbackUrl(coordinates, options),
        headers: headers,
        httpClient: _httpClient,
        abortTrigger: abortObsoleteRequests ? cancelLoading : null,
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
