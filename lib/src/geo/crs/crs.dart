import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:tuple/tuple.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/src/core/bounds.dart';

import 'package:flutter_map/src/core/point.dart';

/// An abstract representation of a
/// [Coordinate Reference System](https://docs.qgis.org/testing/en/docs/gentle_gis_introduction/coordinate_reference_systems.html).
///
/// The main objective of a CRS is to handle the conversion between surface
/// points of objects of different dimensions. In our case 3D and 2D objects.
abstract class Crs {
  String get code;
  Projection get projection;
  Transformation get transformation;

  const Crs();

  /// Converts a point on the sphere surface (with a certain zoom) in a
  /// map point.
  CustomPoint latLngToPoint(LatLng latlng, double zoom) {
    try {
      var projectedPoint = projection.project(latlng);
      var scale = this.scale(zoom);
      return transformation.transform(projectedPoint, scale.toDouble());
    } catch (e) {
      return CustomPoint(0.0, 0.0);
    }
  }

  /// Converts a map point to the sphere coordinate (at a certain zoom).
  LatLng pointToLatLng(CustomPoint point, double zoom) {
    var scale = this.scale(zoom);
    var untransformedPoint =
        transformation.untransform(point, scale.toDouble());
    try {
      return projection.unproject(untransformedPoint);
    } catch (e) {
      return null;
    }
  }

  /// Zoom to Scale function.
  num scale(double zoom) {
    return 256 * math.pow(2, zoom);
  }

  /// Scale to Zoom function.
  num zoom(double scale) {
    return math.log(scale / 256) / math.ln2;
  }

  /// Rescales the bounds to a given zoom value.
  Bounds getProjectedBounds(double zoom) {
    if (infinite) return null;

    var b = projection.bounds;
    var s = scale(zoom);
    var min = transformation.transform(b.min, s.toDouble());
    var max = transformation.transform(b.max, s.toDouble());
    return Bounds(min, max);
  }

  bool get infinite;

  Tuple2<double, double> get wrapLng;

  Tuple2<double, double> get wrapLat;
}

// Custom CRS for non geographical maps
class CrsSimple extends Crs {
  @override
  final String code = 'CRS.SIMPLE';

  @override
  final Projection projection;

  @override
  final Transformation transformation;

  CrsSimple()
      : projection = const _LonLat(),
        transformation = Transformation(1, 0, -1, 0),
        super();

  @override
  bool get infinite => false;

  @override
  Tuple2<double, double> get wrapLat => null;

  @override
  Tuple2<double, double> get wrapLng => null;
}

abstract class Earth extends Crs {
  @override
  bool get infinite => false;

  @override
  final Tuple2<double, double> wrapLng = const Tuple2(-180.0, 180.0);

  @override
  final Tuple2<double, double> wrapLat = null;

  const Earth() : super();
}

/// The most common CRS used for rendering maps.
class Epsg3857 extends Earth {
  @override
  final String code = 'EPSG:3857';

  @override
  final Projection projection;

  @override
  final Transformation transformation;

  static const num _scale = 0.5 / (math.pi * SphericalMercator.r);

  const Epsg3857()
      : projection = const SphericalMercator(),
        transformation = const Transformation(_scale, 0.5, -_scale, 0.5),
        super();

  // TODO Epsg3857 seems to have latitude limits. https://epsg.io/3857
  //@override
  //Tuple2<double, double> get wrapLat => const Tuple2(-85.06, 85.06);
}

abstract class Projection {
  const Projection();

  Bounds<double> get bounds;
  CustomPoint project(LatLng latlng);
  LatLng unproject(CustomPoint point);

  double _inclusive(Comparable start, Comparable end, double value) {
    if (value.compareTo(start) < 0) return start;
    if (value.compareTo(end) > 0) return end;

    return value;
  }

  @protected
  double inclusiveLat(double value) {
    return _inclusive(-90.0, 90.0, value);
  }

  @protected
  double inclusiveLng(double value) {
    if (value.compareTo(-180) < 0) return -180;
    if (value.compareTo(180) > 0) return 180;

    return value;
  }
}

class _LonLat extends Projection {
  static final Bounds<double> _bounds = Bounds<double>(
      CustomPoint<double>(-180.0, -90.0), CustomPoint<double>(180.0, 90.0));

  const _LonLat() : super();

  @override
  Bounds<double> get bounds => _bounds;

  @override
  CustomPoint project(LatLng latlng) {
    return CustomPoint(latlng.longitude, latlng.latitude);
  }

  @override
  LatLng unproject(CustomPoint point) {
    return LatLng(inclusiveLat(point.y), inclusiveLng(point.x));
  }
}

class SphericalMercator extends Projection {
  static const int r = 6378137;
  static const double maxLatitude = 85.0511287798;
  static const double _boundsD = r * math.pi;
  static final Bounds<double> _bounds = Bounds<double>(
    CustomPoint<double>(-_boundsD, -_boundsD),
    CustomPoint<double>(_boundsD, _boundsD),
  );

  const SphericalMercator() : super();

  @override
  Bounds<double> get bounds => _bounds;

  @override
  CustomPoint project(LatLng latlng) {
    var d = math.pi / 180;
    var max = maxLatitude;
    var lat = math.max(math.min(max, latlng.latitude), -max);
    var sin = math.sin(lat * d);

    return CustomPoint(
        r * latlng.longitude * d, r * math.log((1 + sin) / (1 - sin)) / 2);
  }

  @override
  LatLng unproject(CustomPoint point) {
    var d = 180 / math.pi;
    return LatLng(
        inclusiveLat(
            (2 * math.atan(math.exp(point.y / r)) - (math.pi / 2)) * d),
        inclusiveLng(point.x * d / r));
  }
}

class Transformation {
  final num a;
  final num b;
  final num c;
  final num d;
  const Transformation(this.a, this.b, this.c, this.d);

  CustomPoint transform(CustomPoint<num> point, double scale) {
    scale ??= 1.0;
    var x = scale * (a * point.x + b);
    var y = scale * (c * point.y + d);
    return CustomPoint(x, y);
  }

  CustomPoint untransform(CustomPoint point, double scale) {
    scale ??= 1.0;
    var x = (point.x / scale - b) / a;
    var y = (point.y / scale - d) / c;
    return CustomPoint(x, y);
  }
}
