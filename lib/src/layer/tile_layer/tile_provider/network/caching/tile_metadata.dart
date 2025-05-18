import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// Metadata about a tile cached with a [MapCachingProvider]
///
/// Caching is usually determined with HTTP headers. However, if a specific
/// implementation chooses to, it can solely use [staleAt] and set the other
/// properties to a dummy value.
///
/// External usage of this class is not usually necessary. It is visible so
/// other tile providers may make use of it.
@immutable
class CachedMapTileMetadata {
  /// Create new metadata
  ///
  /// [lastModifiedLocally] must be set to [DateTime.timestamp]. Other
  /// properties should usually be set based on the tile's HTTP response
  /// headers.
  const CachedMapTileMetadata({
    required this.lastModifiedLocally,
    required this.staleAt,
    required this.lastModified,
    required this.etag,
  });

  /// Used to efficiently allow updates to already cached tiles
  ///
  /// Must be set to [DateTime.timestamp] when a new tile is cached or a tile
  /// is updated.
  final DateTime lastModifiedLocally;

  /// The date/time at which the tile becomes stale according to the HTTP spec
  final DateTime staleAt;

  /// The tile's last modified HTTP header
  final DateTime? lastModified;

  /// The tile's etag HTTP header
  final String? etag;

  /// Whether the tile is currently stale
  bool get isStale => DateTime.timestamp().isAfter(staleAt);

  @override
  int get hashCode =>
      Object.hash(lastModifiedLocally, staleAt, lastModified, etag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMapTileMetadata &&
          lastModifiedLocally == other.lastModifiedLocally &&
          staleAt == other.staleAt &&
          lastModified == other.lastModified &&
          etag == other.etag);
}
