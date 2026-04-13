/// Headers for HTTP requests and responses.
abstract interface class HttpHeaders {
  /// "Cache control" header tag.
  static const cacheControlHeader = 'cache-control';

  /// "If modified since" header tag.
  static const ifModifiedSinceHeader = 'if-modified-since';

  /// "If none match" header tag.
  static const ifNoneMatchHeader = 'if-none-match';

  /// "Age" header tag.
  static const ageHeader = 'age';

  /// "Expires" header tag.
  static const expiresHeader = 'expires';

  /// "Last modified" header tag.
  static const lastModifiedHeader = 'last-modified';

  /// "Date" header tag.
  static const dateHeader = 'date';

  /// "etag" header tag.
  static const etagHeader = 'etag';
}
