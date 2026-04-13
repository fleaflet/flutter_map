/// HTTP exception.
class HttpException implements Exception {
  /// Message.
  final String message;

  /// Uri.
  final Uri? uri;

  /// Http Exception constructor.
  const HttpException(this.message, {this.uri});

  @override
  String toString() {
    final b = StringBuffer()
      ..write('HttpException: ')
      ..write(message);
    final uri = this.uri;
    if (uri != null) {
      b.write(', uri = $uri');
    }
    return b.toString();
  }
}
