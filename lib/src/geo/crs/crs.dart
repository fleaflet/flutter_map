import 'dart:math' as math;

import 'package:tuple/tuple.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/src/core/bounds.dart';

import 'package:flutter_map/src/core/point.dart';

abstract class Crs {
  String get code;
  Projection get projection;
  Transformation get transformation;

  const Crs();

  CustomPoint latLngToPoint(LatLng latlng, double zoom) {
    try {
      var projectedPoint = this.projection.project(latlng);
      var scale = this.scale(zoom);
      return transformation.transform(projectedPoint, scale.toDouble());
    } catch (e) {
      return new CustomPoint(0.0, 0.0);
    }
  }

  LatLng pointToLatLng(CustomPoint point, double zoom) {
    var scale = this.scale(zoom);
    var untransformedPoint = this.transformation.untransform(point, scale.toDouble());
    try {
      return projection.unproject(untransformedPoint);
    } catch (e) {
      return null;
    }
  }

  num scale(double zoom) {
    return 256 * math.pow(2, zoom);
  }

  num zoom(double scale) {
    return math.log(scale / 256) / math.ln2;
  }

  Bounds getProjectedBounds(double zoom) {
    if (this.infinite) return null;

    var b = projection.bounds;
    var s = this.scale(zoom);
    var min = this.transformation.transform(b.min, s.toDouble());
    var max = this.transformation.transform(b.max, s.toDouble());
    return new Bounds(min, max);
  }

  bool get infinite;
  Tuple2<double, double> get wrapLng;
  Tuple2<double, double> get wrapLat;
}

abstract class Earth extends Crs {
  bool get infinite => false;
  final Tuple2<double, double> wrapLng = const Tuple2(-180.0, 180.0);
  final Tuple2<double, double> wrapLat = null;

  const Earth() : super();
}

class Epsg3857 extends Earth {
  final String code = 'EPSG:3857';
  final Projection projection;
  final Transformation transformation;
  static const num _scale = 0.5 / (math.pi * SphericalMercator.r);
  const Epsg3857()
      : projection = const SphericalMercator(),
        transformation = const Transformation(_scale, 0.5, -_scale, 0.5),
        super();
}

abstract class Projection {
  const Projection();

  Bounds<double> get bounds;
  CustomPoint project(LatLng latlng);
  LatLng unproject(CustomPoint point);
}

class SphericalMercator extends Projection {
  static const int r = 6378137;
  static const double maxLatitude = 85.0511287798;
  static const double _boundsD = r * math.pi;
  static Bounds<double> _bounds = new Bounds<double>(
    new CustomPoint<double>(-_boundsD, -_boundsD),
    new CustomPoint<double>(_boundsD, _boundsD),
  );

  const SphericalMercator() : super();

  Bounds<double> get bounds => _bounds;

  CustomPoint project(LatLng latlng) {
    var d = math.pi / 180;
    var max = maxLatitude;
    var lat = math.max(math.min(max, latlng.latitude), -max);
    var sin = math.sin(lat * d);

    return new CustomPoint(
        r * latlng.longitude * d, r * math.log((1 + sin) / (1 - sin)) / 2);
  }

  LatLng unproject(CustomPoint point) {
    var d = 180 / math.pi;
    return new LatLng(
        (2 * math.atan(math.exp(point.y / r)) - (math.pi / 2)) * d,
        point.x * d / r);
  }
}

class Transformation {
  final num a;
  final num b;
  final num c;
  final num d;
  const Transformation(this.a, this.b, this.c, this.d);

  CustomPoint transform(CustomPoint<num> point, double scale) {
    if (scale == null) {
      scale = 1.0;
    }
    var x = scale * (a * point.x + b);
    var y = scale * (c * point.y + d);
    return new CustomPoint(x, y);
  }

  CustomPoint untransform(CustomPoint point, double scale) {
    if (scale == null) {
      scale = 1.0;
    }
    var x = (point.x / scale - b) / a;
    var y = (point.y / scale - d) / c;
    return new CustomPoint(x, y);
  }
}
