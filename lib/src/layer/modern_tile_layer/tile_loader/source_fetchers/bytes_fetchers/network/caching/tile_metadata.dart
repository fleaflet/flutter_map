import 'dart:io' show HttpHeaders, HttpDate; // web safe!
import 'dart:math';

import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// Metadata about a tile cached with a [MapCachingProvider]
///
/// Caching is usually determined with HTTP headers. However, if a specific
/// implementation chooses to, it can solely use [isStale] and set the other
/// properties to `null`.
///
/// External usage of this class is not usually necessary. It is visible so
/// other tile providers may make use of it.
@immutable
class CachedMapTileMetadata {
  /// Create new metadata
  const CachedMapTileMetadata({
    required this.staleAt,
    required this.lastModified,
    required this.etag,
  });

  /// Create new metadata based off an HTTP response's headers
  ///
  /// Where a response does not include enough information to calculate the
  /// freshness age, [fallbackFreshnessAge] is used.
  factory CachedMapTileMetadata.fromHttpHeaders(
    Map<String, String> headers, {
    Duration fallbackFreshnessAge = const Duration(days: 7),
  }) {
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

      return addToNow(fallbackFreshnessAge);
    }

    final lastModified = headers[HttpHeaders.lastModifiedHeader];
    final etag = headers[HttpHeaders.etagHeader];

    return CachedMapTileMetadata(
      staleAt: calculateStaleAt(),
      lastModified: lastModified != null ? HttpDate.parse(lastModified) : null,
      etag: etag,
    );
  }

  /// The calculated time at which this tile becomes stale (UTC)
  ///
  /// Tile providers should use [isStale] to check whether a tile is stale,
  /// instead of manually comparing this to the current timestamp.
  ///
  /// This may have been calculated based off an HTTP response's headers using
  /// [CachedMapTileMetadata.fromHttpHeaders], or it may be custom.
  final DateTime staleAt;

  /// If available, the value in [HttpHeaders.lastModifiedHeader] (UTC)
  final DateTime? lastModified;

  /// If available, the value in [HttpHeaders.etagHeader]
  final String? etag;

  /// Whether this tile should be considered stale
  ///
  /// Usually this is implemented by storing the timestamp at which the tile
  /// becomes stale, and comparing that to the current timestamp.
  bool get isStale => DateTime.timestamp().isAfter(staleAt);

  @override
  int get hashCode => Object.hash(staleAt, lastModified, etag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMapTileMetadata &&
          staleAt == other.staleAt &&
          lastModified == other.lastModified &&
          etag == other.etag);
}
