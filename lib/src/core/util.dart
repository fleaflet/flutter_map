import 'dart:math';

import 'package:tuple/tuple.dart';

const EARTH_CIRCUMFERENCE_METERS = 40075016.686;

var _templateRe = RegExp(r"\{ *([\w_-]+) *\}");
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

/// Restrict [x] to the range [ [low], [high] ].
///
/// Transcribed to dartlang from MathUtil.java from android-maps-utils library by Google. 
/// https://github.com/googlemaps/android-maps-utils
double clamp(double x, double low, double high) {
  return x < low ? low : (x > high ? high : x);
}

/// Wraps the given value into the inclusive-exclusive interval between min and max.
/// * [n]   The value to wrap.
/// * [min] The minimum.
/// * [max] The maximum.
///
/// Transcribed to dartlang from MathUtil.java from android-maps-utils library by Google. 
/// https://github.com/googlemaps/android-maps-utils
double wrap(double n, double min, double max) {
  return (n >= min && n < max) ? n : (mod(n - min, max - min) + min);
}

/// Returns the non-negative remainder of [x] / [m].
/// * [x] The operand.
/// * [m] The modulus.
///
/// Transcribed to dartlang from MathUtil.java from android-maps-utils library by Google. 
/// https://github.com/googlemaps/android-maps-utils
double mod(double x, double m) {
  return ((x % m) + m) % m;
}

/// Returns mercator Y corresponding to latitude.
/// See http://en.wikipedia.org/wiki/Mercator_projection .
///
/// Transcribed to dartlang from MathUtil.java from android-maps-utils library by Google. 
/// https://github.com/googlemaps/android-maps-utils
double mercator(double lat) {
  return log(tan(lat * 0.5 + pi / 4));
}

/// Returns latitude from mercator Y.
///
/// Transcribed to dartlang from MathUtil.java from android-maps-utils library by Google. 
/// https://github.com/googlemaps/android-maps-utils
double inverseMercator(double y) {
  return 2 * atan(exp(y)) - pi / 2;
}

/// Returns haversine(angle-in-radians).
/// hav([x]) == (1 - cos([x])) / 2 == sin([x] / 2)^2.
///
/// Transcribed to dartlang from MathUtil.java from android-maps-utils library by Google. 
/// https://github.com/googlemaps/android-maps-utils
double hav(double x) {
  double sinHalf = sin(x * 0.5);
  return sinHalf * sinHalf;
}

/// Computes inverse haversine. Has good numerical stability around 0.
/// arcHav([x]) == acos(1 - 2 * [x]) == 2 * asin(sqrt([x])).
/// The argument must be in [0, 1], and the result is positive.
///
/// Transcribed to dartlang from MathUtil.java from android-maps-utils library by Google. 
/// https://github.com/googlemaps/android-maps-utils
double arcHav(double x) {
  return 2 * asin(sqrt(x));
}

/// Given h==hav(x), returns sin(abs(x)).
///
/// Transcribed to dartlang from MathUtil.java from android-maps-utils library by Google. 
/// https://github.com/googlemaps/android-maps-utils
double sinFromHav(double h) {
  return 2 * sqrt(h * (1 - h));
}

/// Returns hav(asin(x)).
///
/// Transcribed to dartlang from MathUtil.java from android-maps-utils library by Google. 
/// https://github.com/googlemaps/android-maps-utils
double havFromSin(double x) {
  double x2 = x * x;
  return x2 / (1 + sqrt(1 - x2)) * .5;
}

/// Returns sin(arcHav(x) + arcHav(y)).
///
/// Transcribed to dartlang from MathUtil.java from android-maps-utils library by Google. 
/// https://github.com/googlemaps/android-maps-utils
double sinSumFromHav(double x, double y) {
  double a = sqrt(x * (1 - x));
  double b = sqrt(y * (1 - y));
  return 2 * (a + b - 2 * (a * y + b * x));
}

/// Returns hav() of distance from (lat1, lng1) to (lat2, lng2) on the unit sphere.
///
/// Transcribed to dartlang from MathUtil.java from android-maps-utils library by Google. 
/// https://github.com/googlemaps/android-maps-utils
double havDistance(double lat1, double lat2, double dLng) {
  return hav(lat1 - lat2) + hav(dLng) * cos(lat1) * cos(lat2);
}
