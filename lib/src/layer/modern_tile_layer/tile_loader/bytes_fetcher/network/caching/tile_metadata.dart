import 'dart:io' show HttpHeaders, HttpDate; // web safe!
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:logger/logger.dart';

/// Metadata about a tile cached with a [MapCachingProvider].
///
/// For output, implementers of a [MapCachingProvider] may:
///  * implement this interface
///  * use or extend [HttpControlledCachedTileMetadata], if the provider makes
///    use of HTTP headers
///  * construct this directly, if the provider does not consider HTTP caching
///
/// For input, implementers of a [MapCachingProvider] may:
///  * accept no metadata/ignore any provided metadata
///  * accept a subclass implementation if metadata is useful
///
/// Consumers of a [MapCachingProvider] should:
///  * (preferably) be accepting of many providers, and
///     * expect this interface to be returned as metadata
///     * provide whatever metadata is likely to be useful (such as
///       [HttpControlledCachedTileMetadata] to be compatible with the
///       [BuiltInMapCachingProvider]), and ensure that type safety is preserved
///  * or, tie to a specific provider implementation and specific metadata
///    implementation
@immutable
interface class CachedTileMetadata {
  const CachedTileMetadata._({required this.isStale});

  /// Whether to consider this tile as stale.
  ///
  /// If `true`, consumers should:
  ///  * attempt to update the tile
  ///  * only use the tile as a fallback
  ///
  /// The meaning & interpretation of `false` depends on the implementation of
  /// the consumer and the caching provider. For example, it may indicate that
  /// the tile should be used without deferring to a second source (network), or
  /// the network may still be attempted anyway - and this may be set on either
  /// implementation.
  final bool isStale;

  /// Non-specific metadata indicating a stale tile.
  ///
  /// This method is likely only to be useful for [MapCachingProvider]
  /// implementations as an output.
  static const stale = CachedTileMetadata._(isStale: true);

  /// Non-specific metadata indicating a non-stale tile.
  ///
  /// This method is likely only to be useful for [MapCachingProvider]
  /// implementations as an output.
  static const fresh = CachedTileMetadata._(isStale: false);
}

/// Implementation of [CachedTileMetadata] which uses properties commonly found
/// in the HTTP Caching specification.
///
/// [isStale] is determined by whether the tile is 'stale', as determined
/// by [staleAt] (which may be calculated from multiple HTTP headers).
///
/// [lastModified] & [etag] are common metadata components which caches may
/// choose to support, which makes HTTP Caching more efficient.
@immutable
base class HttpControlledCachedTileMetadata implements CachedTileMetadata {
  /// Create new metadata based on properties commonly found in the HTTP Caching
  /// specification.
  ///
  /// If constructing from a HTTP response, consider
  /// [HttpControlledCachedTileMetadata.fromHttpHeaders] to automatically
  /// calculate and parse these properties.
  const HttpControlledCachedTileMetadata({
    required this.staleAt,
    this.lastModified,
    this.etag,
  });

  /// Create new metadata based off an HTTP response's headers.
  ///
  /// Where a response does not include enough information to calculate the
  /// freshness age, [fallbackFreshnessAge] is used. This will emit a console
  /// log in debug mode if [warnOnFallbackUsage] is is set.
  ///
  /// This may throw if the required headers were in an unexpected format.
  factory HttpControlledCachedTileMetadata.fromHttpHeaders(
    Map<String, String> headers, {
    Uri? warnOnFallbackUsage,
    Duration fallbackFreshnessAge = const Duration(days: 7),
  }) {
    void warnFallbackUsage() {
      if (kDebugMode && warnOnFallbackUsage != null) {
        Logger(printer: SimplePrinter()).w(
          '[flutter_map] Using fallback freshness age ($fallbackFreshnessAge) '
          'for ${warnOnFallbackUsage.path}\n\tThis indicates the tile server '
          'did not send enough information to calculate a freshness age. '
          "Optionally override in the caching provider's config.",
        );
      }
    }

    // There is no guarantee that this meets the HTTP specification - however,
    // it was designed with it in mind
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

          warnFallbackUsage();
          return addToNow(fallbackFreshnessAge);
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

      warnFallbackUsage();
      return addToNow(fallbackFreshnessAge);
    }

    final lastModified = headers[HttpHeaders.lastModifiedHeader];
    final etag = headers[HttpHeaders.etagHeader];

    return HttpControlledCachedTileMetadata(
      staleAt: calculateStaleAt(),
      lastModified: lastModified != null ? HttpDate.parse(lastModified) : null,
      etag: etag,
    );
  }

  /// The calculated time at which this tile becomes stale (UTC)
  ///
  /// Consumers should refer to [isStale] to determine whether the tile is
  /// stale.
  ///
  /// This may have been calculated based off an HTTP response's headers using
  /// [HttpControlledCachedTileMetadata.fromHttpHeaders], or it may be custom.
  final DateTime staleAt;

  /// If available, the value in [HttpHeaders.lastModifiedHeader] (UTC)
  final DateTime? lastModified;

  /// If available, the value in [HttpHeaders.etagHeader]
  final String? etag;

  @override
  bool get isStale => DateTime.timestamp().isAfter(staleAt);

  @override
  int get hashCode => Object.hash(staleAt, lastModified, etag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HttpControlledCachedTileMetadata &&
          staleAt == other.staleAt &&
          lastModified == other.lastModified &&
          etag == other.etag);
}
