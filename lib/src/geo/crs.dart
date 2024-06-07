import 'dart:math' as math hide Point;
import 'dart:math' show Point;

import 'package:flutter_map/src/misc/bounds.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;

/// An abstract representation of a
/// [Coordinate Reference System](https://bit.ly/3iVKpja).
///
/// The main objective of a CRS is to handle the conversion between surface
/// points of objects of different dimensions. In our case 3D and 2D objects.
@immutable
abstract class Crs {
  /// The code
  @nonVirtual
  final String code;

  /// Set to true if the CRS has no bounds.
  @nonVirtual
  final bool infinite;

  /// Wrap the longitude to fit inside the bounds of the [Crs].
  @nonVirtual
  final (double, double)? wrapLng;

  /// Wrap the latitude to fit inside the bounds of the [Crs].
  @nonVirtual
  final (double, double)? wrapLat;

  /// Constant base constructor that sets all values for the abstract [Crs].
  const Crs({
    required this.code,
    required this.infinite,
    this.wrapLng,
    this.wrapLat,
  });

  /// Project a spherical LatLng coordinate into planar space (unscaled).
  Projection get projection;

  /// Scale planar coordinate to scaled map point.
  (double, double) transform(double x, double y, double scale);

  /// Scale map point to planar coordinate.
  (double, double) untransform(double x, double y, double scale);

  /// Converts a point on the sphere surface (with a certain zoom) to a
  /// scaled map point.
  (double, double) latLngToXY(LatLng latlng, double scale);

  /// Similar to [latLngToXY] but converts the XY coordinates to a [Point].
  Point<double> latLngToPoint(LatLng latlng, double zoom) {
    final (x, y) = latLngToXY(latlng, scale(zoom));
    return Point<double>(x, y);
  }

  /// Converts a map point to the sphere coordinate (at a certain zoom).
  LatLng pointToLatLng(Point point, double zoom);

  /// Zoom to Scale function.
  double scale(double zoom) => 256.0 * math.pow(2, zoom);

  /// Scale to Zoom function.
  double zoom(double scale) => math.log(scale / 256) / math.ln2;

  /// Rescales the bounds to a given zoom value.
  Bounds<double>? getProjectedBounds(double zoom);
}

/// Internal base class for CRS with a single zoom-level independent transformation.
@immutable
@internal
abstract class CrsWithStaticTransformation extends Crs {
  @nonVirtual
  @protected
  final _Transformation _transformation;

  @override
  final Projection projection;

  const CrsWithStaticTransformation._({
    required _Transformation transformation,
    required this.projection,
    required super.code,
    required super.infinite,
    super.wrapLng,
    super.wrapLat,
  }) : _transformation = transformation;

  @override
  (double, double) transform(double x, double y, double scale) =>
      _transformation.transform(x, y, scale);

  @override
  (double, double) untransform(double x, double y, double scale) =>
      _transformation.untransform(x, y, scale);

  @override
  (double, double) latLngToXY(LatLng latlng, double scale) {
    final (x, y) = projection.projectXY(latlng);
    return _transformation.transform(x, y, scale);
  }

  @override
  LatLng pointToLatLng(Point point, double zoom) {
    final (x, y) = _transformation.untransform(
      point.x.toDouble(),
      point.y.toDouble(),
      scale(zoom),
    );
    return projection.unprojectXY(x, y);
  }

  @override
  Bounds<double>? getProjectedBounds(double zoom) {
    if (infinite) return null;

    final b = projection.bounds!;
    final s = scale(zoom);
    final (minx, miny) = _transformation.transform(b.min.x, b.min.y, s);
    final (maxx, maxy) = _transformation.transform(b.max.x, b.max.y, s);
    return Bounds<double>(
      Point<double>(minx, miny),
      Point<double>(maxx, maxy),
    );
  }
}

/// Custom CRS for non geographical maps
@immutable
class CrsSimple extends CrsWithStaticTransformation {
  /// Create a new [CrsSimple].
  const CrsSimple()
      : super._(
          code: 'CRS.SIMPLE',
          transformation: const _Transformation(1, 0, -1, 0),
          projection: const _LonLat(),
          infinite: false,
          wrapLat: null,
          wrapLng: null,
        );
}

/// EPSG:3857, The most common CRS used for rendering maps.
@immutable
class Epsg3857 extends CrsWithStaticTransformation {
  static const double _scale = 0.5 / (math.pi * SphericalMercator.r);

  /// Create a new [Epsg3857] object.
  const Epsg3857()
      : super._(
          code: 'EPSG:3857',
          transformation: const _Transformation(_scale, 0.5, -_scale, 0.5),
          projection: const SphericalMercator(),
          infinite: false,
          wrapLng: const (-180, 180),
        );

  @override
  (double, double) latLngToXY(LatLng latlng, double scale) =>
      _transformation.transform(
        SphericalMercator.projectLng(latlng.longitude),
        SphericalMercator.projectLat(latlng.latitude),
        scale,
      );

  @override
  Point<double> latLngToPoint(LatLng latlng, double zoom) {
    final (x, y) = _transformation.transform(
      SphericalMercator.projectLng(latlng.longitude),
      SphericalMercator.projectLat(latlng.latitude),
      scale(zoom),
    );
    return Point<double>(x, y);
  }
}

/// EPSG:4326, A common CRS among GIS enthusiasts.
/// Uses simple Equirectangular projection.
@immutable
class Epsg4326 extends CrsWithStaticTransformation {
  /// Create a new [Epsg4326] CRS instance.
  const Epsg4326()
      : super._(
          projection: const _LonLat(),
          transformation: const _Transformation(1 / 180, 1, -1 / 180, 0.5),
          code: 'EPSG:4326',
          infinite: false,
          wrapLng: const (-180, 180),
        );
}

/// Custom CRS
@immutable
class Proj4Crs extends Crs {
  @override
  final Projection projection;
  final List<_Transformation> _transformations;
  final List<double> _scales;

  const Proj4Crs._({
    required super.code,
    required this.projection,
    required super.infinite,
    required List<_Transformation> transformations,
    required List<double> scales,
  })  : _transformations = transformations,
        _scales = scales,
        super(wrapLat: null, wrapLng: null);

  /// Create a new [Crs] that has projection.
  factory Proj4Crs.fromFactory({
    required String code,
    required proj4.Projection proj4Projection,
    List<Point<double>>? origins,
    Bounds<double>? bounds,
    List<double>? scales,
    List<double>? resolutions,
  }) {
    final projection = _Proj4Projection(
      proj4Projection: proj4Projection,
      bounds: bounds,
    );

    List<double> finalScales;
    if (null != scales && scales.isNotEmpty) {
      finalScales = scales;
    } else if (null != resolutions && resolutions.isNotEmpty) {
      finalScales = resolutions.map((r) => 1 / r).toList(growable: false);
    } else {
      throw Exception(
          'Please provide scales or resolutions to determine scales');
    }

    List<_Transformation> transformations;
    if (null == origins || origins.isEmpty) {
      transformations = [const _Transformation(1, 0, -1, 0)];
    } else {
      if (origins.length == 1) {
        final origin = origins[0];
        transformations = [_Transformation(1, -origin.x, -1, origin.y)];
      } else {
        transformations =
            origins.map((p) => _Transformation(1, -p.x, -1, p.y)).toList();
      }
    }

    return Proj4Crs._(
      code: code,
      projection: projection,
      infinite: null == bounds,
      transformations: transformations,
      scales: finalScales,
    );
  }

  @override
  (double, double) transform(double x, double y, double scale) =>
      _getTransformationByZoom(zoom(scale)).transform(x, y, scale);

  @override
  (double, double) untransform(double x, double y, double scale) =>
      _getTransformationByZoom(zoom(scale)).untransform(x, y, scale);

  /// Converts a point on the sphere surface (with a certain zoom) in a
  /// map point.
  @override
  (double, double) latLngToXY(LatLng latlng, double scale) {
    final (x, y) = projection.projectXY(latlng);
    final transformation = _getTransformationByZoom(zoom(scale));
    return transformation.transform(x, y, scale);
  }

  /// Converts a map point to the sphere coordinate (at a certain zoom).
  @override
  LatLng pointToLatLng(Point point, double zoom) {
    final (x, y) = _getTransformationByZoom(zoom).untransform(
      point.x.toDouble(),
      point.y.toDouble(),
      scale(zoom),
    );
    return projection.unprojectXY(x, y);
  }

  /// Rescales the bounds to a given zoom value.
  @override
  Bounds<double>? getProjectedBounds(double zoom) {
    if (infinite) return null;

    final b = projection.bounds!;
    final zoomScale = scale(zoom);

    final transformation = _getTransformationByZoom(zoom);
    final (minx, miny) = transformation.transform(b.min.x, b.min.y, zoomScale);
    final (maxx, maxy) = transformation.transform(b.max.x, b.max.y, zoomScale);
    return Bounds<double>(
      Point<double>(minx, miny),
      Point<double>(maxx, maxy),
    );
  }

  /// Zoom to Scale function.
  @override
  double scale(double zoom) {
    final iZoom = zoom.floor();
    if (zoom == iZoom) {
      return _scales[iZoom];
    } else {
      // Non-integer zoom, interpolate
      final baseScale = _scales[iZoom];
      final nextScale = _scales[iZoom + 1];
      final scaleDiff = nextScale - baseScale;
      final zDiff = zoom - iZoom;
      return baseScale + scaleDiff * zDiff;
    }
  }

  /// Scale to Zoom function.
  @override
  double zoom(double scale) {
    // Find closest number in _scales, down
    final downScale = _closestElement(_scales, scale);
    if (downScale == null) {
      return double.negativeInfinity;
    }
    final downZoom = _scales.indexOf(downScale);
    // Check if scale is downScale => return array index
    if (scale == downScale) {
      return downZoom.toDouble();
    }
    // Interpolate
    final nextZoom = downZoom + 1;
    final nextScale = _scales[nextZoom];

    final scaleDiff = nextScale - downScale;
    return (scale - downScale) / scaleDiff + downZoom;
  }

  /// Get the closest lowest element in an array
  double? _closestElement(List<double> array, double element) {
    double? low;
    for (var i = array.length - 1; i >= 0; i--) {
      final curr = array[i];

      if (curr <= element && (null == low || low < curr)) {
        low = curr;
      }
    }
    return low;
  }

  /// returns Transformation object based on zoom
  _Transformation _getTransformationByZoom(double zoom) {
    final iZoom = zoom.round();
    final lastIdx = _transformations.length - 1;
    return _transformations[iZoom > lastIdx ? lastIdx : iZoom];
  }
}

/// The abstract base [Projection] class, used for coordinate reference
/// systems like [Epsg3857].
/// Inherit from this class if you want to create or implement your own CRS.
@immutable
abstract class Projection {
  /// The [Bounds] for the coordinates of this [Projection].
  final Bounds<double>? bounds;

  /// Base constructor for the abstract [Projection] class that sets the
  /// required fields.
  const Projection(this.bounds);

  /// Converts a [LatLng] to a coordinates and returns them as [Point] object.
  @nonVirtual
  Point<double> project(LatLng latlng) {
    final (x, y) = projectXY(latlng);
    return Point<double>(x, y);
  }

  /// Converts a [LatLng] to geometry coordinates.
  (double, double) projectXY(LatLng latlng);

  /// unproject a cartesian Point to [LatLng].
  @nonVirtual
  LatLng unproject(Point point) =>
      unprojectXY(point.x.toDouble(), point.y.toDouble());

  /// unproject cartesian x,y coordinates to [LatLng].
  LatLng unprojectXY(double x, double y);
}

class _LonLat extends Projection {
  static const _bounds = Bounds<double>.unsafe(
    Point<double>(-180, -90),
    Point<double>(180, 90),
  );

  const _LonLat() : super(_bounds);

  @override
  (double, double) projectXY(LatLng latlng) =>
      (latlng.longitude, latlng.latitude);

  @override
  LatLng unprojectXY(double x, double y) =>
      LatLng(_inclusiveLat(y), _inclusiveLng(x));
}

/// Spherical mercator projection
@immutable
class SphericalMercator extends Projection {
  /// The radius
  static const int r = 6378137;

  /// The maximum latitude
  static const double maxLatitude = 85.0511287798;

  static const double _boundsD = r * math.pi;

  /// The constant Bounds of the [SphericalMercator] projection.
  static const Bounds<double> _bounds = Bounds<double>.unsafe(
    Point<double>(-_boundsD, -_boundsD),
    Point<double>(_boundsD, _boundsD),
  );

  /// Constant constructor for the [SphericalMercator] projection.
  const SphericalMercator() : super(_bounds);

  /// Project the latitude for this [Crs]
  static double projectLat(double latitude) {
    final lat = _clampSym(latitude, maxLatitude);
    final sin = math.sin(lat * math.pi / 180);

    return r / 2 * math.log((1 + sin) / (1 - sin));
  }

  /// Project the longitude for this [Crs]
  static double projectLng(double longitude) {
    return r * math.pi / 180 * longitude;
  }

  @override
  (double, double) projectXY(LatLng latlng) {
    return (
      projectLng(latlng.longitude),
      projectLat(latlng.latitude),
    );
  }

  @override
  LatLng unprojectXY(double x, double y) {
    const d = 180 / math.pi;
    return LatLng(
      _inclusiveLat((2 * math.atan(math.exp(y / r)) - (math.pi / 2)) * d),
      _inclusiveLng(x * d / r),
    );
  }
}

@immutable
class _Proj4Projection extends Projection {
  final proj4.Projection epsg4326;
  final proj4.Projection proj4Projection;

  _Proj4Projection({
    required this.proj4Projection,
    required Bounds<double>? bounds,
  })  : epsg4326 = proj4.Projection.WGS84,
        super(bounds);

  @override
  (double, double) projectXY(LatLng latlng) {
    final point = epsg4326.transform(
        proj4Projection, proj4.Point(x: latlng.longitude, y: latlng.latitude));

    return (point.x, point.y);
  }

  @override
  LatLng unprojectXY(double x, double y) {
    final point = proj4Projection.transform(epsg4326, proj4.Point(x: x, y: y));

    return LatLng(
      _inclusiveLat(point.y),
      _inclusiveLng(point.x),
    );
  }
}

@immutable
class _Transformation {
  final double a;
  final double b;
  final double c;
  final double d;

  const _Transformation(this.a, this.b, this.c, this.d);

  @nonVirtual
  (double, double) transform(double x, double y, double scale) => (
        scale * (a * x + b),
        scale * (c * y + d),
      );

  @nonVirtual
  (double, double) untransform(double x, double y, double scale) => (
        (x / scale - b) / a,
        (y / scale - d) / c,
      );
}

// Num.clamp is slow due to virtual function overhead.
double _clampSym(double value, double limit) =>
    value < -limit ? -limit : (value > limit ? limit : value);

double _inclusiveLat(double value) => _clampSym(value, 90);

double _inclusiveLng(double value) => _clampSym(value, 180);
