import 'dart:async';
import 'dart:io' show HttpHeaders, HttpDate, HttpStatus; // web safe!

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/network/caching/built_in/built_in_caching_provider.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/network/caching/caching_provider.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/network/caching/disabled/disabled_caching_provider.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/network/caching/tile_metadata.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/network/caching/tile_read_failure_exception.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/network/fetcher/consolidate_response.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:logger/logger.dart';

/// A [SourceBytesFetcher] which fetches from the network using HTTP, based on
/// their [TileSource]
@immutable
class NetworkBytesFetcher
    with ImageChunkEventsSupport<Iterable<String>>
    implements SourceBytesFetcher<Iterable<String>> {
  /// HTTP headers to send with each request
  final Map<String, String> headers;

  /// HTTP client used to make each request
  ///
  /// It is much more efficient if a single client is used repeatedly, as it
  /// can maintain an open socket connection to the server.
  ///
  /// Where possible, clients should support aborting of requests when the
  /// response is no longer required.
  final Client httpClient;

  /// Provider used to perform long-term tile caching.
  ///
  /// See online documentation for more information about built-in caching.
  ///
  /// Defaults to [BuiltInMapCachingProvider]. Set to
  /// [DisabledMapCachingProvider] to disable.
  final MapCachingProvider? cachingProvider;

  /// Whether to optimistically attempt to decode HTTP responses that have a
  /// non-successful status code as an image
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

  /// A tile bytes fetcher which fetches from the network using HTTP, based on
  /// their [TileSource]
  ///
  /// The string "flutter_map ([uaIdentifier])" is set as the 'User-Agent' HTTP
  /// header on non-web platforms, if the UA header is not specified manually.
  /// If not provided, the string "flutter_map (unknown)" is used.
  /// [uaIdentifier] should uniquely identify your app or project - for example,
  /// 'com.example.app'.
  ///
  /// > [!TIP]
  /// > Setting a [uaIdentifier] (or a custom UA header) is strongly recommended
  /// > for all projects. It helps the server differentiate your traffic from
  /// > other flutter_map traffic.
  /// >
  /// > A useful UA header is required by the terms of service of many tile
  /// > servers. flutter_map places some restrictions on projects if a UA header
  /// > is left unset.
  NetworkBytesFetcher({
    String? uaIdentifier,
    Map<String, String>? headers,
    Client? httpClient,
    this.cachingProvider,
    this.attemptDecodeOfHttpErrorResponses = true,
    this.abortObsoleteRequests = true,
  })  : headers = headers ?? {},
        httpClient = httpClient ?? RetryClient(Client()) {
    if (!kIsWeb) {
      this.headers.putIfAbsent(
            HttpHeaders.userAgentHeader,
            () => 'flutter_map ($uaIdentifier)',
          );
    }
  }

  @override
  Future<R> withImageChunkEventsSink<R>({
    required Iterable<String> source,
    required Future<void> abortSignal,
    required BytesToResourceTransformer<R> transformer,
    StreamSink<ImageChunkEvent>? chunkEvents,
  }) async {
    final iterator = source.iterator;

    if (!iterator.moveNext()) {
      throw ArgumentError('At least one URI must be provided', 'source');
    }

    for (bool isPrimary = true;; isPrimary = false) {
      try {
        return await _fetch(
          uri: iterator.current,
          abortSignal: abortSignal,
          transformer: isPrimary
              ? transformer
              : (bytes, {allowReuse = true}) =>
                  // In fallback scenarios, we never allow reuse of bytes in the
                  // short-term cache (or long-term cache)
                  transformer(bytes, allowReuse: false),
          chunkEvents: chunkEvents,
          performLongTermCaching: !isPrimary,
        );
      } on TileAbortedException {
        rethrow; // Never try fallbacks on abortion
      } on Exception {
        if (iterator.moveNext()) {
          // Attempt fallbacks
          // TODO: Consider logging
          continue;
        }
        rethrow; // No more fallbacks available
      }
    }
  }

  Future<R> _fetch<R>({
    required String uri,
    required Future<void> abortSignal,
    required BytesToResourceTransformer<R> transformer,
    required StreamSink<ImageChunkEvent>? chunkEvents,
    required bool performLongTermCaching,
  }) async {
    final parsedUri = Uri.parse(uri);

    // Create method to get bytes from server
    Future<({Uint8List bytes, StreamedResponse response})> get({
      Map<String, String>? additionalHeaders,
    }) async {
      final request = AbortableRequest(
        'GET',
        parsedUri,
        abortTrigger: abortObsoleteRequests ? abortSignal : null,
      );

      request.headers.addAll(headers);
      if (additionalHeaders != null) request.headers.addAll(additionalHeaders);

      final response = await httpClient.send(request);

      final bytes = await consolidateStreamedResponseBytes(
        response,
        onBytesReceived: chunkEvents == null
            ? null
            : (cumulative, total) => chunkEvents.add(
                  ImageChunkEvent(
                    cumulativeBytesLoaded: cumulative,
                    expectedTotalBytes: total,
                  ),
                ),
      );

      return (bytes: bytes, response: response);
    }

    // Prepare caching provider & load cached tile if available
    CachedMapTile? cachedTile;
    final cachingProvider =
        this.cachingProvider ?? BuiltInMapCachingProvider.getOrCreateInstance();
    if (cachingProvider.isSupported) {
      try {
        cachedTile = await cachingProvider.getTile(uri);
      } on CachedMapTileReadFailure {
        // This could occur due to a corrupt tile - we just try to overwrite it
        // with fresh data
        cachedTile = null;
      }
    }

    // Create method to write response to cache when applicable
    void cachePut({
      required Uint8List? bytes,
      required Map<String, String> headers,
    }) {
      if (performLongTermCaching || !cachingProvider.isSupported) return;

      // TODO: Consider best way to silence these 2 logs
      late final CachedMapTileMetadata metadata;
      try {
        metadata = CachedMapTileMetadata.fromHttpHeaders(
          headers,
          warnOnFallbackUsage: parsedUri,
        );
      } on Exception catch (e) {
        if (kDebugMode) {
          Logger(printer: SimplePrinter()).w(
            '[flutter_map cache] Failed to cache ${parsedUri.path}: $e\n\tThis '
            'may indicate a HTTP spec non-conformance issue with the tile '
            'server. ',
          );
        }
        return;
      }

      cachingProvider.putTile(url: uri, metadata: metadata, bytes: bytes);
    }

    // Main logic
    // All `transformer` calls should be awaited so errors may be handled
    try {
      bool forceFromServer = false;
      if (cachedTile != null && !cachedTile.metadata.isStale) {
        try {
          // If we have a cached tile that's not stale, return it
          return await transformer(cachedTile.bytes);
        } on Exception {
          // If the cached tile is corrupt, we proceed and get from the server
          forceFromServer = true;
        }
      }

      // Otherwise, ask the server what's going on - supply any details we have
      var (:bytes, :response) = await get(
        additionalHeaders: forceFromServer
            ? null
            : {
                if (cachedTile?.metadata.lastModified case final lastModified?)
                  HttpHeaders.ifModifiedSinceHeader:
                      HttpDate.format(lastModified),
                if (cachedTile?.metadata.etag case final etag?)
                  HttpHeaders.ifNoneMatchHeader: etag,
              },
      );

      // Server says nothing's changed - but might return new useful headers
      if (!forceFromServer &&
          cachedTile != null &&
          response.statusCode == HttpStatus.notModified) {
        late final R transformedCacheBytes;
        try {
          transformedCacheBytes = await transformer(cachedTile.bytes);
        } on Exception {
          // If the cached tile is corrupt, we get fresh from the server without
          // caching, then continue
          forceFromServer = true;
          (:bytes, :response) = await get();
        }
        if (!forceFromServer) {
          cachePut(bytes: null, headers: response.headers);
          return transformedCacheBytes;
        }
      }

      // Server says the image has changed - store it new
      if (response.statusCode == HttpStatus.ok) {
        cachePut(bytes: bytes, headers: response.headers);
        return await transformer(bytes);
      }

      // It's likely an error at this point
      // However, some servers may produce error responses with useful bodies,
      // perhaps intentionally (such as an "API Key Required" message)
      // Therefore, if there is a body, and the user allows it, we attempt to
      // decode the body bytes as an image (although we don't cache if
      // successful)
      // Otherwise, we just throw early
      if (!attemptDecodeOfHttpErrorResponses || bytes.isEmpty) {
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: parsedUri,
        );
      }

      try {
        return await transformer(bytes, allowReuse: false);
      } catch (_, stackTrace) {
        // If it throws, we don't want to throw the decode error, as that's not
        // useful for users
        // Instead, we throw an exception reporting the failed HTTP request,
        // which is caught by the non-specific catch block below to initiate the
        // retry/silence mechanisms if applicable
        // We do retain the stack trace, so that it might be clear we attempted
        // to decode it
        // We piggyback off of an error meant for `NetworkImage` - it's the same
        // as we need
        Error.throwWithStackTrace(
          NetworkImageLoadException(
            statusCode: response.statusCode,
            uri: parsedUri,
          ),
          stackTrace,
        );
      }
    } on RequestAbortedException catch (_, stackTrace) {
      // This is a planned exception, we convert the error

      Error.throwWithStackTrace(
        TileAbortedException(source: parsedUri),
        stackTrace,
      );
    } on ClientException catch (err, stackTrace) {
      // This could be a wide range of issues, potentially ours, potentially
      // network, etc.

      // Try to detect errors thrown from requests being aborted due to the
      // client being closed
      // This can occur when the map/tile layer is disposed early - in older
      // versions, we used manual tracking to avoid disposing too early, but now
      // we just attempt to catch (it's cleaner & easier)
      if (err.message.contains('closed') || err.message.contains('cancel')) {
        Error.throwWithStackTrace(
          TileAbortedException(source: parsedUri),
          stackTrace,
        );
      }

      rethrow; // Otherwise, attempt fallbacks
    }
    // We may also get exceptions otherwise, for example from failing to
    // transform/decode bytes or `NetworkImageLoadException` - we pass these
    // through to the caller to allow attempting of fallbacks implicitly
  }
}
