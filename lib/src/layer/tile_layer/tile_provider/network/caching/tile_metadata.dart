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
    required DateTime staleAt,
    required DateTime? lastModified,
    required this.etag,
  })  : _staleAt = staleAt.millisecondsSinceEpoch,
        _lastModified = lastModified?.millisecondsSinceEpoch;

  /// Decode metadata from JSON
  CachedMapTileMetadata.fromJson(Map<String, dynamic> json)
      : _staleAt = json['a'] as int,
        _lastModified = json.containsKey('b') ? json['b'] as int : null,
        etag = json.containsKey('c') ? json['c'] as String : null;

  final int _staleAt;

  /// If available, the value in [HttpHeaders.lastModifiedHeader]
  DateTime? get lastModified => _lastModified == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(_lastModified);
  final int? _lastModified;

  /// If available, the value in [HttpHeaders.etagHeader]
  final String? etag;

  /// Whether this tile should be considered stale
  ///
  /// Usually this is implemented by storing the timestamp at which the tile
  /// becomes stale, and comparing that to the current timestamp.
  bool get isStale => DateTime.timestamp().millisecondsSinceEpoch > _staleAt;

  /// Encode the metadata to JSON
  Map<String, dynamic> toJson() => {
        'a': _staleAt,
        if (_lastModified != null) 'b': _lastModified,
        if (etag != null) 'c': etag,
      };

  @override
  int get hashCode => Object.hash(_staleAt, lastModified, etag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMapTileMetadata &&
          _staleAt == other._staleAt &&
          lastModified == other.lastModified &&
          etag == other.etag);
}
