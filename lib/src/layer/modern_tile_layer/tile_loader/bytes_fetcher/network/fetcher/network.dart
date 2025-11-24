import 'dart:async';
import 'dart:io' show HttpHeaders, HttpDate, HttpStatus; // web safe!

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/bytes_fetcher/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/bytes_fetcher/network/fetcher/consolidate_response.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:logger/logger.dart';

/// A [SourceBytesFetcher] which fetches a URI from the network using HTTP.
///
/// {@template fm.sbf.default.sourceConsumption}
/// Consumes an [Iterable] of [String] URIs, which must not be empty and
/// iterates in an order. If the first URI cannot be used to fetch bytes, the
/// next URI is used as a fallback if available, and so on.
/// {@endtemplate}
///
/// Supports caching, delegating to a [MapCachingProvider].
///  * If a non-stale tile is available, it is used without using the network
///  * If a stale tile is available, it is updated if possible, otherwise the
///    behaviour depends on [fallbackToStaleCachedTiles]
@immutable
class NetworkBytesFetcher implements SourceBytesFetcher<Iterable<String>> {
  /// HTTP headers to send with each request.
  final Map<String, String> headers;

  /// HTTP client used to make each request.
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
  /// If a cached tile is available and not stale, it will be used without
  /// attempting the network.
  ///
  /// Defaults to [BuiltInMapCachingProvider]. Set to
  /// [DisabledMapCachingProvider] to disable.
  final MapCachingProvider? cachingProvider;

  /// Whether to use a potentially stale cached tile if it could not be
  /// retrieved from the network.
  ///
  /// Only applicable if [cachingProvider] is in use.
  ///
  /// Defaults to `true`.
  final bool fallbackToStaleCachedTiles;

  /// Whether to optimistically attempt to decode HTTP responses that have a
  /// non-successful status code as an image.
  ///
  /// Some servers return useful information embedded in an image returned in
  /// the HTTP body of a non-successful response, such as an instruction to use
  /// an API key. This can make it easier to debug issues.
  ///
  /// Defaults to `true` in debug mode, `false` otherwise.
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

  /// A [SourceBytesFetcher] which fetches from the network using HTTP.
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
    this.fallbackToStaleCachedTiles = true,
    this.attemptDecodeOfHttpErrorResponses = kDebugMode,
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
  Future<R> call<R>({
    required Iterable<String> source,
    required Future<void> abortSignal,
    required BytesToResourceTransformer<R> transformer,
    BytesReceivedCallback? bytesLoadedCallback,
  }) =>
      fetchFromSourceIterable(
        (uri, transformer, isFirst) => fetchSingle(
          uri: uri,
          abortSignal: abortSignal,
          transformer: transformer,
          bytesLoadedCallback: bytesLoadedCallback,
        ),
        source: source,
        transformer: transformer,
      );

  /// Fetch a single URI's resource
  ///
  /// This is used internally but exposed for convenience.
  ///
  /// This throws when an error is encountered attempting to access the
  /// resource.
  Future<R> fetchSingle<R>({
    required String uri,
    required Future<void> abortSignal,
    required BytesToResourceTransformer<R> transformer,
    BytesReceivedCallback? bytesLoadedCallback,
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
        onBytesReceived: bytesLoadedCallback,
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
      // If any other error is thrown, fetching is stopped & rethrown
    }

    // Create method to write response to cache when applicable
    // Even when fetching a fallback, we can still use the long-term cache, as
    // it safely associates it with the resolved URI. This is not possible for
    // the short-term cache, as it would require the I/O work to occur before
    // the short-term cache key could be resolved.
    void cachePut({
      required Uint8List? bytes,
      required Map<String, String> headers,
    }) {
      if (!cachingProvider.isSupported) return;

      if (cachingProvider
          case final PutTileAndMetadataCapability<
              HttpControlledCachedTileMetadata> cachingProvider) {
        late final HttpControlledCachedTileMetadata metadata;
        try {
          metadata = HttpControlledCachedTileMetadata.fromHttpHeaders(
            headers,
            warnOnFallbackUsage: parsedUri,
          );
        } on Exception catch (e) {
          if (kDebugMode) {
            Logger(printer: SimplePrinter()).w(
              '[flutter_map] Failed to cache ${parsedUri.path}: $e\n\tThis '
              'may indicate a HTTP spec non-conformance issue with the tile '
              'server. ',
            );
          }
          return;
        }

        cachingProvider.putTileWithMetadata(
          url: uri,
          metadata: metadata,
          bytes: bytes,
        );
      } else if (cachingProvider case final PutTileCapability cachingProvider) {
        cachingProvider.putTile(url: uri, bytes: bytes);
      } else if (kDebugMode) {
        Logger(printer: SimplePrinter()).w(
          '[flutter_map] Caching provider incompatible with '
          '`NetworkBytesFetcher` for put operations',
        );
      }
    }

    // Create the exception exit method
    // In the event that a tile cannot be fetched from the network, and a
    // (stale) cached tile is available, and the behaviour is allowed, attempt
    // to use the cached resource. This method is used on exit when a
    // non-abortion exception occurs. Otherwise, it rethrows the original
    // exception to the caller, which may attempt fallbacks.
    Future<R> fallbackToCachedTile(Object err, StackTrace stackTrace) async {
      if (cachedTile == null || !fallbackToStaleCachedTiles) {
        Error.throwWithStackTrace(err, stackTrace);
      }
      try {
        final cachedResource =
            await transformer(cachedTile.bytes, allowReuse: false);
        if (kDebugMode) {
          Logger(printer: SimplePrinter()).w(
            '[flutter_map] Failed to fetch ${parsedUri.path} from network; '
            'using (stale) cached tile',
          );
        }
        return cachedResource;
      } on Exception {
        Error.throwWithStackTrace(err, stackTrace);
      }
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
                if (cachedTile?.metadata
                    case HttpControlledCachedTileMetadata(:final lastModified?))
                  HttpHeaders.ifModifiedSinceHeader:
                      HttpDate.format(lastModified),
                if (cachedTile?.metadata
                    case HttpControlledCachedTileMetadata(:final etag?))
                  HttpHeaders.ifNoneMatchHeader: etag,
              },
      );

      // Server says nothing's changed - but might return new useful headers
      // This should usually only happen when `!forceFromServer`
      if (cachedTile != null && response.statusCode == HttpStatus.notModified) {
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

      // Server says the image has changed
      if (response.statusCode == HttpStatus.ok) {
        final resource = await transformer(bytes);
        // If the transformer fails, the error will be caught by an outer
        // try/catch block, and the bytes won't be put to the cache
        cachePut(bytes: bytes, headers: response.headers);
        return resource;
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
      } on Exception catch (_, stackTrace) {
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

      return await fallbackToCachedTile(err, stackTrace);
    } on Exception catch (err, stackTrace) {
      // We may also get exceptions otherwise, for example from failing to
      // transform/decode bytes or `NetworkImageLoadException`

      return await fallbackToCachedTile(err, stackTrace);
    }
  }
}
