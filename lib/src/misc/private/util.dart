import 'dart:async';

var _templateRe = RegExp(r'\{ *([\w_-]+) *\}');

/// Replaces the templating placeholders with the provided data map.
///
/// Example input: https://tile.openstreetmap.org/{z}/{x}/{y}.png
///
/// Throws an [Exception] if any placeholder remains unresolved.
String template(String str, Map<String, String> data) {
  return str.replaceAllMapped(_templateRe, (match) {
    final firstMatch = match.group(1);
    if (firstMatch == null) {
      throw Exception('incorrect URL template: $str');
    }
    final value = data[firstMatch];
    if (value == null) {
      throw Exception('No value provided for variable ${match.group(1)}');
    } else {
      return value;
    }
  });
}

StreamTransformer<T, T> throttleStreamTransformerWithTrailingCall<T>(
  Duration duration, {
  bool Function(T)? ignore,
}) {
  Timer? timer;
  T recentData;
  var trailingCall = false;

  late final void Function(T data, EventSink<T> sink) throttleHandler;

  throttleHandler = (data, sink) {
    if (ignore?.call(data) ?? false) return;

    recentData = data;

    if (timer == null) {
      sink.add(recentData);
      timer = Timer(duration, () {
        timer = null;

        if (trailingCall) {
          trailingCall = false;
          throttleHandler(recentData, sink);
        }
      });
    } else {
      trailingCall = true;
    }
  };

  return StreamTransformer<T, T>.fromHandlers(
      handleData: throttleHandler,
      handleDone: (sink) {
        timer?.cancel();
        sink.close();
      });
}
