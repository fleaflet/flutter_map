import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
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

StreamTransformer<T, T> throttleStreamTransformerWithTrailingCall<T>(
    Duration duration) {
  Timer timer;
  T recentData;
  var trailingCall = false;

  void Function(T data, EventSink<T> sink) throttleHandler;
  throttleHandler = (T data, EventSink<T> sink) {
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
      handleDone: (EventSink<T> sink) {
        timer?.cancel();
        sink.close();
      });
}

Widget wrapLayer(
    Widget layer, MapState map, LayerOptions options, bool setKey) {
  var size = options.rotationEnabled ? map.size : map.originalSize;
  var angle = options.rotationEnabled ? map.rotationRad : 0.0;

  return OverflowBox(
    key: setKey ? options.key : null,
    minWidth: size.x,
    maxWidth: size.x,
    minHeight: size.y,
    maxHeight: size.y,
    child: Transform.rotate(
      angle: angle,
      child: layer,
    ),
  );
}
