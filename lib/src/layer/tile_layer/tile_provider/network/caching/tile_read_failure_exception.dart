/// Indicates that the tile with the given URL was present in the cache, but
/// could not be correctly read
///
/// This may be due to an unexpected corruption. It should not be thrown when
/// the tile was written correctly.
///
/// Tile providers should catch this exception. Wherever possible, they should
/// repair or replace the tile with a fresh & valid one.
///
/// The absence of this exception does not necessarily mean that the returned
/// tile image bytes are valid, only that all the correctly written information
/// was successfully read.
///
/// This exception is not usually for external consumption, except for tile
/// provider implementations.
class CachedMapTileReadFailure implements Exception {
  /// Create an exception which indicates the tile with the given URL was
  /// present in the cache, but could not be correctly read
  ///
  /// Usually, one of [description] or [originalError] should be provided.
  const CachedMapTileReadFailure({
    required this.url,
    this.description,
    this.originalError,
  });

  /// URL of the failed tile
  final String url;

  /// An optional description of the read failure which caused this to be thrown
  ///
  /// Usually, one of [description] or [originalError] should be provided.
  final String? description;

  /// If available, the original error/exception which caused this to be thrown
  /// (if not thrown manually)
  ///
  /// Usually, one of [description] or [originalError] should be provided.
  final Object? originalError;

  @override
  String toString() =>
      'Failed to read cached tile for $url: ${description ?? originalError}';
}
