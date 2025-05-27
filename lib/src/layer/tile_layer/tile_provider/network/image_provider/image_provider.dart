import 'dart:async';
import 'dart:io' show HttpHeaders, HttpDate, HttpStatus; // this is web safe!
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/image_provider/consolidate_response.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

/// Dedicated [ImageProvider] to fetch tiles from the network
///
/// Supports falling back to a secondary URL, if the primary URL fetch fails.
/// Note that specifying a [fallbackUrl] will prevent this image provider from
/// being cached.
@immutable
@internal
class NetworkTileImageProvider extends ImageProvider<NetworkTileImageProvider> {
  /// The URL to fetch the tile from (GET request)
  final String url;

  /// The URL to fetch the tile from (GET request), in the event the original
  /// [url] request fails
  ///
  /// If this is non-null, [operator==] will always return `false` (except if
  /// the two objects are [identical]). Therefore, if this is non-null, this
  /// image provider will not be cached in memory.
  final String? fallbackUrl;

  /// The headers to include with the tile fetch request
  ///
  /// Not included in [operator==].
  final Map<String, String> headers;

  /// The HTTP client to use to make network requests
  ///
  /// Not included in [operator==].
  final Client httpClient;

  /// Completes when the tile request should be aborted
  ///
  /// Not included in [operator==].
  final Future<void>? abortTrigger;

  /// Whether to ignore exceptions and errors that occur whilst fetching tiles
  /// over the network, and just return a transparent tile
  ///
  /// Not included in [operator==].
  final bool silenceExceptions;

  /// Whether to optimistically attempt to decode HTTP responses that have a
  /// non-successful status code as an image
  ///
  /// Not included in [operator==].
  final bool attemptDecodeOfHttpErrorResponses;

  /// Caching provider used to get cached tiles
  ///
  /// See online documentation for more information about built-in caching.
  ///
  /// Defaults to [BuiltInMapCachingProvider]. Set to
  /// [DisabledMapCachingProvider] to disable.
  ///
  /// Not included in [operator==].
  final MapCachingProvider? cachingProvider;

  /// Create a dedicated [ImageProvider] to fetch tiles from the network
  ///
  /// Supports falling back to a secondary URL, if the primary URL fetch fails.
  /// Note that specifying a [fallbackUrl] will prevent this image provider from
  /// being cached.
  const NetworkTileImageProvider({
    required this.url,
    required this.fallbackUrl,
    required this.headers,
    required this.httpClient,
    required this.abortTrigger,
    required this.silenceExceptions,
    required this.attemptDecodeOfHttpErrorResponses,
    required this.cachingProvider,
  });

  @override
  ImageStreamCompleter loadImage(
    NetworkTileImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadImage(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: 1,
      debugLabel: key.url,
      informationCollector: () => [
        DiagnosticsProperty('URL', url),
        DiagnosticsProperty('Fallback URL', fallbackUrl),
        DiagnosticsProperty('Current provider', key),
      ],
    );
  }

  Future<Codec> _loadImage(
    NetworkTileImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode, {
    bool useFallback = false,
  }) async {
    // Create utility methods
    void evict() =>
        scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
    Future<Codec> decodeBytes(Uint8List bytes) =>
        ImmutableBuffer.fromUint8List(bytes).then(decode);

    // Resolve URIs
    final resolvedUrl = useFallback ? fallbackUrl ?? '' : url;
    final Uri uri;
    try {
      uri = Uri.parse(resolvedUrl);
    } on FormatException {
      evict();
      chunkEvents.close();
      rethrow;
    }

    // Prepare caching provider & load cached tile if available
    ({Uint8List bytes, CachedMapTileMetadata metadata})? cachedTile;
    final cachingProvider =
        this.cachingProvider ?? BuiltInMapCachingProvider.getOrCreateInstance();
    if (cachingProvider.isSupported) {
      try {
        cachedTile = await cachingProvider.getTile(resolvedUrl);
      } on Exception {
        cachedTile = null;
      }
    }

    // Create method to get bytes from server
    Future<({Uint8List bytes, StreamedResponse response})> get({
      Map<String, String>? additionalHeaders,
    }) async {
      // TODO: Support cancellation
      // final request = AbortableRequest('GET', uri, abortTrigger: abortTrigger);
      final request = Request('GET', uri);

      request.headers.addAll(headers);
      if (additionalHeaders != null) request.headers.addAll(additionalHeaders);

      final response = await httpClient.send(request);

      final bytes = await consolidateStreamedResponseBytes(
        response,
        onBytesReceived: (cumulative, total) => chunkEvents.add(
          ImageChunkEvent(
            cumulativeBytesLoaded: cumulative,
            expectedTotalBytes: total,
          ),
        ),
      );

      return (bytes: bytes, response: response);
    }

    // Create method to interact with cache
    void cachePut({
      required Uint8List? bytes,
      required Map<String, String> headers,
    }) {
      if (!cachingProvider.isSupported) return;

      final lastModified = headers[HttpHeaders.lastModifiedHeader];
      final etag = headers[HttpHeaders.etagHeader];

      DateTime calculateStaleAt() {
        final addToNow = DateTime.timestamp().add;

        if (headers[HttpHeaders.cacheControlHeader]?.toLowerCase()
            case final cacheControl?) {
          final maxAge = RegExp(r'max-age=(\d+)').firstMatch(cacheControl)?[1];

          if (maxAge == null) {
            if (headers[HttpHeaders.expiresHeader]?.toLowerCase()
                case final expires?) {
              return HttpDate.parse(expires);
            }

            return addToNow(const Duration(days: 7));
          }

          if (headers[HttpHeaders.ageHeader] case final currentAge?) {
            return addToNow(
              Duration(seconds: int.parse(maxAge) - int.parse(currentAge)),
            );
          }

          final estimatedAge = max(
            0,
            DateTime.timestamp()
                .difference(HttpDate.parse(headers[HttpHeaders.dateHeader]!))
                .inSeconds,
          );
          return addToNow(Duration(seconds: int.parse(maxAge) - estimatedAge));
        }

        return addToNow(const Duration(days: 7));
      }

      cachingProvider.putTile(
        url: resolvedUrl,
        metadata: CachedMapTileMetadata(
          staleAt: calculateStaleAt(),
          lastModified:
              lastModified != null ? HttpDate.parse(lastModified) : null,
          etag: etag,
        ),
        bytes: bytes,
      );
    }

    // Main logic
    // All `decodeBytes` calls should be awaited so errors may be handled
    try {
      if (cachedTile != null && !cachedTile.metadata.isStale) {
        // If we have a cached tile that's not stale, return it
        return await decodeBytes(cachedTile.bytes);
      }

      // Otherwise, ask the server what's going on - supply any details we have
      final (:bytes, :response) = await get(
        additionalHeaders: {
          if (cachedTile?.metadata.lastModified case final lastModified?)
            HttpHeaders.ifModifiedSinceHeader: HttpDate.format(lastModified),
          if (cachedTile?.metadata.etag case final etag?)
            HttpHeaders.ifNoneMatchHeader: etag,
        },
      );

      // Server says nothing's changed - but might return new useful headers
      if (cachedTile != null && response.statusCode == HttpStatus.notModified) {
        cachePut(bytes: null, headers: response.headers);
        return await decodeBytes(cachedTile.bytes);
      }

      // Server says the image has changed - store it new
      if (response.statusCode == HttpStatus.ok) {
        cachePut(bytes: bytes, headers: response.headers);
        return await decodeBytes(bytes);
      }

      // It's likely an error at this point
      // If the user has disabled attempted-decode, we just throw and catch
      // below
      // Otherwise we try to decode it anyway, without memory caching
      if (!attemptDecodeOfHttpErrorResponses) {
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: uri,
        );
      }
      evict();
      try {
        return await decodeBytes(bytes);
      } catch (err, stackTrace) {
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
            uri: uri,
          ),
          stackTrace,
        );
      }
    }
    // TODO: Support cancellation
    /* on AbortedRequest {
      // This is a planned exception, we just quit silently

      evict();
      chunkEvents.close();
      return await decodeBytes(TileProvider.transparentImage);
    } */
    on ClientException catch (e) {
      // This could be a wide range of issues, potentially ours, potentially
      // network, etc.

      evict();

      // Try to detect errors thrown from requests being aborted due to the
      // client being closed
      // This can occur when the map/tile layer is disposed early - in older
      // versions, we used manual tracking to avoid disposing too early, but now
      // we just attempt to catch (it's cleaner & easier)
      if (e.message.contains('closed') || e.message.contains('cancel')) {
        return await decodeBytes(TileProvider.transparentImage);
      }

      if (useFallback || fallbackUrl == null) {
        chunkEvents.close();
        if (!silenceExceptions) rethrow;
        return await decodeBytes(TileProvider.transparentImage);
      }
      return _loadImage(key, chunkEvents, decode, useFallback: true);
    } catch (e) {
      // Non-specific catch to catch decoding errors, the manually thrown HTTP
      // exception, etc.

      evict();

      if (useFallback || fallbackUrl == null) {
        chunkEvents.close();
        if (!silenceExceptions) rethrow;
        return await decodeBytes(TileProvider.transparentImage);
      }
      return _loadImage(key, chunkEvents, decode, useFallback: true);
    }
  }

  @override
  SynchronousFuture<NetworkTileImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) =>
      SynchronousFuture(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NetworkTileImageProvider &&
          fallbackUrl == null &&
          other.fallbackUrl == null &&
          url == other.url);

  @override
  int get hashCode =>
      Object.hashAll([url, if (fallbackUrl != null) fallbackUrl]);
}
