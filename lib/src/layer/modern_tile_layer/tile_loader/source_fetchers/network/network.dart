import 'dart:io' show HttpHeaders; // web safe!

import 'package:flutter/foundation.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source.dart';
import 'package:flutter_map/src/layer/modern_tile_layer/tile_loader/source_generator_fetcher.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

class NetworkBytesFetcher implements TileSourceFetcher<TileSource, Uint8List> {
  final Map<String, String> headers;
  final Client httpClient;

  NetworkBytesFetcher({
    Map<String, String>? headers,
    Client? httpClient,
  })  : headers = headers ?? {},
        httpClient = httpClient ?? RetryClient(Client());

  NetworkBytesFetcher.withUAIdentifier(
    String identifier, {
    Map<String, String>? headers,
    Client? httpClient,
  })  : headers = headers ?? {},
        httpClient = httpClient ?? RetryClient(Client()) {
    if (!kIsWeb) {
      this.headers.putIfAbsent(
            HttpHeaders.userAgentHeader,
            () => 'flutter_map ($identifier)',
          );
    }
  }

  @override
  Future<Uint8List> call(
    TileSource source,
    Future<void> abortSignal, {
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
      return this(source, abortSignal, useFallback: true);
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
