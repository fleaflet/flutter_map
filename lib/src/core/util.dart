import 'dart:math' as math;
import 'dart:ui';

import 'package:tuple/tuple.dart';
import 'package:latlong/latlong.dart';

const earthCircumferenceMeters = 40075016.686;

var _templateRe = new RegExp(r"\{ *([\w_-]+) *\}");
String template(String str, Map<String, String> data) {
  return str.replaceAllMapped(_templateRe, (Match match) {
    var value = data[match.group(1)];
    if (value == null) {
      throw ("No value provided for variable ${match.group(1)}");
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

double getMetersPerPixel(double pixelsPerTile, double zoom, double latitude) {
  double numTiles = math.pow(2, zoom).toDouble();
  double metersPerTile =
      math.cos(degToRadian(latitude)) * earthCircumferenceMeters / numTiles;
  return metersPerTile / pixelsPerTile;
}

/// Use the Liang-Barsky algorithm to find the intersection points
/// between a line segment and an axis-aligned rectangle.
///
/// See https://gist.github.com/ChickenProp/3194723
bool intersects(Offset p1, Offset p2, Rect rect) {
  Offset v = p2 - p1;
  var p = [-v.dx, v.dx, -v.dy, v.dy];
  var q = [
    p1.dx - rect.left,
    rect.right - p1.dx,
    p1.dy - rect.top,
    rect.bottom - p1.dy
  ];
  var u1 = double.negativeInfinity;
  var u2 = double.infinity;

  for (var i in [0,1,2,3]) {
    if (p[i] == 0) {
      if (q[i] < 0)
        return false;
    }
    else {
      var t = q[i] / p[i];
      if (p[i] < 0 && u1 < t)
        u1 = t;
      else if (p[i] > 0 && u2 > t)
        u2 = t;
    }
  }

  if (u1 > u2 || u1 > 1 || u1 < 0)
    return false;

  return true;
}