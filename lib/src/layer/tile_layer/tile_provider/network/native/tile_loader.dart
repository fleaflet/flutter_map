import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/base_tile_provider.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/independent/caching/tile_metadata.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/independent/image_provider.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/native/caching/manager.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/web/tile_loader.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:uuid/data.dart';
import 'package:uuid/rng.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid(goptions: GlobalOptions(MathRNG()));

@internal
Future<Codec> loadTileImage(
  NetworkTileImageProvider key,
  ImageDecoderCallback decode, {
  bool useFallback = false,
}) =>
    _ioLoadTileImage(key, decode, useFallback: useFallback);

Future<Codec> _ioLoadTileImage(
  NetworkTileImageProvider key,
  ImageDecoderCallback decode, {
  bool useFallback = false,
}) async {
  key.startedLoading();

  if (key.cachingOptions == null) {
    return simpleLoadTileImage(key, decode, useFallback: useFallback);
  }
  final MapTileCachingManager cachingManager;
  try {
    cachingManager = await MapTileCachingManager.getInstance(
      options: key.cachingOptions!,
    );
  } catch (_) {
    return simpleLoadTileImage(key, decode, useFallback: useFallback);
  }

  final resolvedUrl = useFallback ? key.fallbackUrl ?? '' : key.url;
  final uuid = key.cachingOptions!.cacheKeyGenerator?.call(resolvedUrl) ??
      _uuid.v5(Namespace.url.value, resolvedUrl);

  final cachedTile = await cachingManager.getTile(uuid);

  Future<Codec> handleOk(Response response) async {
    final lastModified = response.headers[HttpHeaders.lastModifiedHeader];
    final etag = response.headers[HttpHeaders.etagHeader];

    unawaited(cachingManager.putTile(
      uuid,
      CachedMapTileMetadata(
        lastModifiedLocally: DateTime.timestamp(),
        staleAt: _calculateStaleAt(
          response,
          overrideFreshAge: key.cachingOptions!.overrideFreshAge,
        ),
        lastModified:
            lastModified != null ? HttpDate.parse(lastModified) : null,
        etag: etag,
      ),
      response.bodyBytes,
    ));

    return ImmutableBuffer.fromUint8List(response.bodyBytes).then(decode);
  }

  Future<Codec> handleNotOk(Response response) async {
    // Optimistically try to decode the response anyway
    try {
      return await decode(
        await ImmutableBuffer.fromUint8List(response.bodyBytes),
      );
    } catch (err) {
      // Otherwise fallback to a cached tile if we have one
      if (cachedTile != null) {
        return ImmutableBuffer.fromUint8List(cachedTile.bytes).then(decode);
      }

      // Otherwise fallback to the fallback URL
      if (!useFallback && key.fallbackUrl != null) {
        return _ioLoadTileImage(key, decode, useFallback: true);
      }

      // Otherwise throw an exception/silently fail
      if (!key.silenceExceptions) {
        throw HttpException(
          'Recieved ${response.statusCode}, and body was not a decodable image',
          uri: Uri.parse(resolvedUrl),
        );
      }

      return ImmutableBuffer.fromUint8List(TileProvider.transparentImage)
          .then(decode);
    } finally {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
    }
  }

  if (cachedTile != null) {
    // If we have a cached tile that's not stale, return it
    if (!cachedTile.tileInfo.isStale) {
      key.finishedLoadingBytes();
      return ImmutableBuffer.fromUint8List(cachedTile.bytes).then(decode);
    }

    // Otherwise, ask the server what's going on - supply any details we have
    final response = await key.httpClient.get(
      Uri.parse(resolvedUrl),
      headers: {
        ...key.headers,
        if (cachedTile.tileInfo.lastModified case final lastModified?)
          HttpHeaders.ifModifiedSinceHeader: HttpDate.format(lastModified),
        if (cachedTile.tileInfo.etag case final etag?)
          HttpHeaders.ifNoneMatchHeader: etag,
      },
    );
    key.finishedLoadingBytes();

    // Server says nothing's changed - but might return new useful headers
    if (response.statusCode == HttpStatus.notModified) {
      final lastModified = response.headers[HttpHeaders.lastModifiedHeader];
      final etag = response.headers[HttpHeaders.etagHeader];

      unawaited(cachingManager.putTile(
        uuid,
        CachedMapTileMetadata(
          lastModifiedLocally: DateTime.timestamp(),
          staleAt: _calculateStaleAt(
            response,
            overrideFreshAge: key.cachingOptions!.overrideFreshAge,
          ),
          lastModified: lastModified != null
              ? HttpDate.parse(lastModified)
              : cachedTile.tileInfo.lastModified,
          etag: etag ?? cachedTile.tileInfo.etag,
        ),
      ));

      return ImmutableBuffer.fromUint8List(cachedTile.bytes).then(decode);
    }

    if (response.statusCode == HttpStatus.ok) {
      return await handleOk(response);
    }
    return await handleNotOk(response);
  }

  final response = await key.httpClient.get(
    Uri.parse(resolvedUrl),
    headers: key.headers,
  );
  key.finishedLoadingBytes();

  if (response.statusCode == HttpStatus.ok) {
    return await handleOk(response);
  }
  return await handleNotOk(response);
}

DateTime _calculateStaleAt(
  Response response, {
  required Duration? overrideFreshAge,
}) {
  final addToNow = DateTime.timestamp().add;

  if (overrideFreshAge case final overrideFreshAge?) {
    return addToNow(overrideFreshAge);
  }

  if (response.headers[HttpHeaders.cacheControlHeader]?.toLowerCase()
      case final cacheControl?) {
    final maxAge = RegExp(r'max-age=(\d+)').firstMatch(cacheControl)?[1];

    if (maxAge == null) {
      if (response.headers[HttpHeaders.expiresHeader]?.toLowerCase()
          case final expires?) {
        return HttpDate.parse(expires);
      }

      return addToNow(const Duration(days: 7));
    }

    if (response.headers[HttpHeaders.ageHeader] case final currentAge?) {
      return addToNow(
        Duration(seconds: int.parse(maxAge) - int.parse(currentAge)),
      );
    }

    final estimatedAge = max(
      0,
      DateTime.timestamp()
          .difference(HttpDate.parse(response.headers[HttpHeaders.dateHeader]!))
          .inSeconds,
    );
    return addToNow(Duration(seconds: int.parse(maxAge) - estimatedAge));
  }

  return addToNow(const Duration(days: 7));
}
