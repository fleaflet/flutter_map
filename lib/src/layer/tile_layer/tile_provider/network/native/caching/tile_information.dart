part of 'manager.dart';

/// Metadata about a tile cached with the [MapTileCachingManager]
@immutable
class CachedTileInformation {
  /// Create a new metadata container
  ///
  /// [lastModifiedLocally] should be set to [DateTime.timestamp]. Other
  /// properties should be set based on the tile's HTTP response headers.
  const CachedTileInformation({
    required this.lastModifiedLocally,
    required this.staleAt,
    required this.lastModified,
    required this.etag,
  });

  /// Decode metadata from JSON
  CachedTileInformation.fromJson(Map<String, dynamic> json)
      : lastModifiedLocally =
            HttpDate.parse(json['lastModifiedLocally'] as String),
        staleAt = HttpDate.parse(json['staleAt'] as String),
        lastModified = json.containsKey('lastModified') &&
                (json['lastModified'] as String).isNotEmpty
            ? HttpDate.parse(json['lastModified'] as String)
            : null,
        etag = json.containsKey('etag') && (json['etag'] as String).isNotEmpty
            ? json['etag'] as String
            : null;

  /// Used to efficiently allow updates to already cached tiles
  ///
  /// Must be set to [DateTime.timestamp] when a new tile is cached or a tile
  /// is updated.
  final DateTime lastModifiedLocally;

  /// The date/time at which the tile becomes stale according to the HTTP spec
  final DateTime staleAt;

  /// The tile's [HttpHeaders.lastModifiedHeader]
  final DateTime? lastModified;

  /// The tile's [HttpHeaders.etagHeader]
  final String? etag;

  /// Whether the tile is currently stale
  bool get isStale => DateTime.timestamp().isAfter(staleAt);

  /// Convert the metadata to JSON
  Map<String, String> toJson() => {
        'lastModifiedLocally': HttpDate.format(lastModifiedLocally),
        'staleAt': HttpDate.format(staleAt),
        if (lastModified != null)
          'lastModified': HttpDate.format(lastModified!),
        if (etag != null) 'etag': etag!,
      };

  @override
  int get hashCode =>
      Object.hash(lastModifiedLocally, staleAt, lastModified, etag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedTileInformation &&
          lastModifiedLocally == other.lastModifiedLocally &&
          staleAt == other.staleAt &&
          lastModified == other.lastModified &&
          etag == other.etag);
}
