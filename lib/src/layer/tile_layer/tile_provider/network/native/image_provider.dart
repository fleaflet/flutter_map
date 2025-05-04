import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/native/caching/manager.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/native/caching/options.dart';
import 'package:http/http.dart';
import 'package:uuid/data.dart';
import 'package:uuid/rng.dart';
import 'package:uuid/uuid.dart';

/// Dedicated [ImageProvider] to fetch tiles from the network
///
/// Supports falling back to a secondary URL, if the primary URL fetch fails.
/// Note that specifying a [fallbackUrl] will prevent this image provider from
/// being cached.
@immutable
class CachingNetworkTileImageProvider
    extends ImageProvider<CachingNetworkTileImageProvider> {
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

  /// Whether to ignore exceptions and errors that occur whilst fetching tiles
  /// over the network, and just return a transparent tile
  final bool silenceExceptions;

  /// Configuration of built-in caching
  ///
  /// See online documentation for more information about built-in caching.
  ///
  /// Set to `null` to disable. See [MapCachingOptions] for defaults.
  final MapCachingOptions? cachingOptions;

  /// Function invoked when the image starts loading (not from cache)
  ///
  /// Used with [finishedLoadingBytes] to safely dispose of the [httpClient] only
  /// after all tiles have loaded.
  final void Function() startedLoading;

  /// Function invoked when the image completes loading bytes from the network
  ///
  /// Used with [finishedLoadingBytes] to safely dispose of the [httpClient] only
  /// after all tiles have loaded.
  final void Function() finishedLoadingBytes;

  /// Create a dedicated [ImageProvider] to fetch tiles from the network
  ///
  /// Supports falling back to a secondary URL, if the primary URL fetch fails.
  /// Note that specifying a [fallbackUrl] will prevent this image provider from
  /// being cached.
  const CachingNetworkTileImageProvider({
    required this.url,
    required this.fallbackUrl,
    required this.headers,
    required this.httpClient,
    required this.silenceExceptions,
    required this.cachingOptions,
    required this.startedLoading,
    required this.finishedLoadingBytes,
  });

  static final _uuid = Uuid(goptions: GlobalOptions(MathRNG()));

  @override
  ImageStreamCompleter loadImage(
    CachingNetworkTileImageProvider key,
    ImageDecoderCallback decode,
  ) =>
      MultiFrameImageStreamCompleter(
        codec: _load(key, decode),
        scale: 1,
        debugLabel: url,
        informationCollector: () => [
          DiagnosticsProperty('URL', url),
          DiagnosticsProperty('Fallback URL', fallbackUrl),
          DiagnosticsProperty('Current provider', key),
        ],
      );

  Future<Codec> _load(
    CachingNetworkTileImageProvider key,
    ImageDecoderCallback decode, {
    bool useFallback = false,
  }) async {
    startedLoading();

    final resolvedUrl = useFallback ? fallbackUrl ?? '' : url;
    final uuid = _uuid.v5(Namespace.url.value, resolvedUrl);

    // TODO: Allow disabling caching
    final cachingManager = (await MapTileCachingManager.getInstanceOrCreate(
      options: cachingOptions,
    ))!;
    // TODO: Remove force null check, then fallback to non-caching

    final cachedTile = await cachingManager.getTile(uuid);

    Future<Codec> handleOk(Response response) async {
      final lastModified = response.headers[HttpHeaders.lastModifiedHeader];
      final etag = response.headers[HttpHeaders.etagHeader];

      cachingManager.putTile(
        uuid,
        CachedTileInformation(
          lastModifiedLocally: DateTime.timestamp(),
          staleAt: _calculateStaleAt(response),
          lastModified:
              lastModified != null ? HttpDate.parse(lastModified) : null,
          etag: etag,
        ),
        response.bodyBytes,
      );

      finishedLoadingBytes();
      return ImmutableBuffer.fromUint8List(response.bodyBytes).then(decode);
    }

    Future<Codec> handleNotOk(Response response) async {
      // Optimistically try to decode the response anyway
      try {
        finishedLoadingBytes();
        return await decode(
          await ImmutableBuffer.fromUint8List(response.bodyBytes),
        );
      } catch (err) {
        // Otherwise fallback to a cached tile if we have one
        if (cachedTile != null) {
          finishedLoadingBytes();
          return ImmutableBuffer.fromUint8List(cachedTile.bytes).then(decode);
        }

        // Otherwise fallback to the fallback URL
        if (!useFallback && fallbackUrl != null) {
          finishedLoadingBytes();
          return _load(key, decode, useFallback: true);
        }

        // Otherwise throw an exception/silently fail
        if (!silenceExceptions) {
          finishedLoadingBytes();
          throw HttpException(
            'Recieved ${response.statusCode}, and body was not a decodable image',
            uri: Uri.parse(resolvedUrl),
          );
        }

        finishedLoadingBytes();
        return ImmutableBuffer.fromUint8List(TileProvider.transparentImage)
            .then(decode);
      } finally {
        scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      }
    }

    if (cachedTile != null) {
      // If we have a cached tile that's not stale, return it
      if (!cachedTile.tileInfo.isStale) {
        print('from ache');
        finishedLoadingBytes();
        return ImmutableBuffer.fromUint8List(cachedTile.bytes).then(decode);
      }

      // Otherwise, ask the server what's going on - supply any details we have
      final response = await httpClient.get(
        Uri.parse(resolvedUrl),
        headers: {
          ...headers,
          if (cachedTile.tileInfo.lastModified case final lastModified?)
            HttpHeaders.ifModifiedSinceHeader: HttpDate.format(lastModified),
          if (cachedTile.tileInfo.etag case final etag?)
            HttpHeaders.ifNoneMatchHeader: etag,
        },
      );

      // Server says nothing's changed - but might return new useful headers
      if (response.statusCode == HttpStatus.notModified) {
        final lastModified = response.headers[HttpHeaders.lastModifiedHeader];
        final etag = response.headers[HttpHeaders.etagHeader];

        cachingManager.putTile(
          uuid,
          CachedTileInformation(
            lastModifiedLocally: DateTime.timestamp(),
            staleAt: _calculateStaleAt(response),
            lastModified: lastModified != null
                ? HttpDate.parse(lastModified)
                : cachedTile.tileInfo.lastModified,
            etag: etag ?? cachedTile.tileInfo.etag,
          ),
        );

        finishedLoadingBytes();
        return ImmutableBuffer.fromUint8List(cachedTile.bytes).then(decode);
      }

      if (response.statusCode == HttpStatus.ok) {
        return await handleOk(response);
      }
      return await handleNotOk(response);
    }

    final response = await httpClient.get(
      Uri.parse(resolvedUrl),
      headers: headers,
    );

    if (response.statusCode == HttpStatus.ok) {
      return await handleOk(response);
    }
    return await handleNotOk(response);
  }

  static DateTime _calculateStaleAt(Response response) {
    final addToNow = DateTime.timestamp().add;

    if (response.headers[HttpHeaders.cacheControlHeader]?.toLowerCase()
        case final cacheControl?) {
      final maxAge = RegExp(r'max-age=(\d+)').firstMatch(cacheControl)?[1];

      if (maxAge == null) {
        if (response.headers[HttpHeaders.expiresHeader]?.toLowerCase()
            case final expires?) {
          return HttpDate.parse(expires);
        }
        return addToNow(const Duration(days: 7));
      } else {
        if (response.headers[HttpHeaders.ageHeader] case final currentAge?) {
          return addToNow(
            Duration(seconds: int.parse(maxAge) - int.parse(currentAge)),
          );
        }

        final estimatedAge = max(
          0,
          DateTime.timestamp()
              .difference(
                HttpDate.parse(response.headers[HttpHeaders.dateHeader]!),
              )
              .inSeconds,
        );
        return addToNow(
          Duration(seconds: int.parse(maxAge) - estimatedAge),
        );
      }
    } else {
      return addToNow(const Duration(days: 7));
    }
  }

  @override
  SynchronousFuture<CachingNetworkTileImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) =>
      SynchronousFuture(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachingNetworkTileImageProvider &&
          fallbackUrl == null &&
          url == other.url);

  @override
  int get hashCode =>
      Object.hashAll([url, if (fallbackUrl != null) fallbackUrl]);
}
