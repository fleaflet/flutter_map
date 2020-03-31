import 'dart:async';

import 'package:tuple/tuple.dart';

var _templateRe = RegExp(r'\{ *([\w_-]+) *\}');

/// Replaces the templating placeholders with the provided data map.
///
/// Throws an [Exception] if any placeholder remains unresolved.
String template(String str, Map<String, String> data) {
  return str.replaceAllMapped(_templateRe, (Match match) {
    var value = data[match.group(1)];
    if (value == null) {
      throw Exception('No value provided for variable ${match.group(1)}');
    } else {
      return value;
    }
  });
}

double wrapNum(double x, Tuple2<double, double> range, [bool includeMax]) {
  var max = range.item2;
  var min = range.item1;
  var d = max - min;
  return x == max && includeMax != null ? x : ((x - min) % d + d) % d + min;
}

Stream<T> bindAndCreateThrottleStreamWithTrailingCall<T>(
    StreamController<T> sc, Duration duration) {
  Timer timer;
  T recentData;
  var isClosed = false;
  var trailingCall = false;

  return StreamTransformer<T, T>.fromHandlers(
      handleData: (T data, EventSink<T> sink) {
    recentData = data;

    if (timer == null) {
      if (!trailingCall) {
        sink.add(recentData);

        timer = Timer(duration, () {
          timer = null;

          if (trailingCall) {
            trailingCall = false;

            if (!isClosed) {
              sc.add(recentData);
            }
          }
        });
      }
    } else {
      trailingCall = true;
    }
  }, handleDone: (EventSink<T> sink) {
    isClosed = true;
    sink.close();
  }).bind(sc.stream);
}
