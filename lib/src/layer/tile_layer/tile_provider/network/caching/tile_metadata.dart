import 'dart:io' show HttpHeaders; // web safe!

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
  CachedMapTileMetadata({
    required this.staleAt,
    required this.lastModified,
    required this.etag,
  })  : staleAtMilliseconds = staleAt.millisecondsSinceEpoch,
        lastModifiedMilliseconds = lastModified?.millisecondsSinceEpoch;

  /// The calculated time at which this tile becomes stale
  final DateTime staleAt;

  /// The calculated time at which this tile becomes stale, represented in
  /// [DateTime.millisecondsSinceEpoch]
  final int staleAtMilliseconds;

  /// If available, the value in [HttpHeaders.lastModifiedHeader]
  final DateTime? lastModified;

  /// If available, the value in [HttpHeaders.lastModifiedHeader], represented
  /// in [DateTime.millisecondsSinceEpoch]
  final int? lastModifiedMilliseconds;

  /// If available, the value in [HttpHeaders.etagHeader]
  final String? etag;

  /// Whether this tile should be considered stale
  ///
  /// Usually this is implemented by storing the timestamp at which the tile
  /// becomes stale, and comparing that to the current timestamp.
  bool get isStale => DateTime.timestamp().isAfter(staleAt);

  @override
  int get hashCode =>
      Object.hash(staleAtMilliseconds, lastModifiedMilliseconds, etag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMapTileMetadata &&
          staleAtMilliseconds == other.staleAtMilliseconds &&
          lastModifiedMilliseconds == other.lastModifiedMilliseconds &&
          etag == other.etag);
}
