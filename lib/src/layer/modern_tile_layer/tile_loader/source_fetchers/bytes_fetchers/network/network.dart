import 'dart:async';
import 'dart:io' show HttpHeaders; // web safe!

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_fetchers/bytes_fetchers/bytes_fetcher.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/tile_source.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

/// A tile bytes fetcher which fetches from the network using HTTP, based on
/// their [TileSource]
@immutable
class NetworkBytesFetcher
    with ImageChunkEventsSupport<TileSource>
    implements TileBytesFetcher<TileSource> {
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

  // TODO: Add caching provider integration

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
  FutureOr<Uint8List> withImageChunkEventsSink(
    TileSource source,
    Future<void> abortSignal, {
    StreamSink<ImageChunkEvent>? chunkEvents,
    bool useFallback = false,
  }) {
    // TODO: Replace with #2082
    return httpClient
        .readBytes(
      Uri.parse(useFallback ? source.fallbackUri! : source.uri),
      headers: headers,
    )
        .onError<Exception>((err, _) {
      if (useFallback || source.fallbackUri == null) {
        throw err;
      }
      return withImageChunkEventsSink(
        source,
        abortSignal,
        chunkEvents: chunkEvents,
        useFallback: true,
      );
    });
  }

  @override
  int get hashCode => Object.hash(headers, httpClient);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NetworkBytesFetcher &&
          other.headers == headers &&
          other.httpClient == httpClient);
}
