import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart';

/// Data structure representing rectangular bounding box constrained by its
/// northwest and southeast corners
class LatLngBounds {
  /// The latitude north edge of the bounds
  double north;

  /// The latitude south edge of the bounds
  double south;

  /// The longitude east edge of the bounds
  double east;

  /// The longitude west edge of the bounds
  double west;

  /// Create new [LatLngBounds] by providing two corners. Both corners have to
  /// be on opposite sites but it doesn't matter which opposite corners or in
  /// what order the corners are provided.
  ///
  /// If you want to create [LatLngBounds] with raw values, use the
  /// [LatLngBounds.unsafe] constructor instead.
  factory LatLngBounds(LatLng corner1, LatLng corner2) {
    final double minX;
    final double maxX;
    final double minY;
    final double maxY;
    if (corner1.longitude >= corner2.longitude) {
      maxX = corner1.longitude;
      minX = corner2.longitude;
    } else {
      maxX = corner2.longitude;
      minX = corner1.longitude;
    }
    if (corner1.latitude >= corner2.latitude) {
      maxY = corner1.latitude;
      minY = corner2.latitude;
    } else {
      maxY = corner2.latitude;
      minY = corner1.latitude;
    }
    return LatLngBounds.unsafe(
      north: maxY,
      south: minY,
      east: maxX,
      west: minX,
    );
  }

  /// Create a [LatLngBounds] instance from raw edge values.
  ///
  /// Potentially throws assertion errors if the coordinates exceed their max
  /// or min values or if coordinates are meant to be smaller / bigger
  /// but aren't.
  LatLngBounds.unsafe({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  })  : assert(
            north <= 90, "The north latitude can't be bigger than 90: $north"),
        assert(north >= -90,
            "The north latitude can't be smaller than -90: $north"),
        assert(
            south <= 90, "The south latitude can't be bigger than 90: $south"),
        assert(south >= -90,
            "The south latitude can't be smaller than -90: $south"),
        assert(
            east <= 180, "The east longitude can't be bigger than 180: $east"),
        assert(east >= -180,
            "The east longitude can't be smaller than -180: $east"),
        assert(
            west <= 180, "The west longitude can't be bigger than 180: $west"),
        assert(west >= -180,
            "The west longitude can't be smaller than -180: $west"),
        assert(north >= south,
            "The north latitude can't be smaller than the south latitude"),
        assert(east >= west,
            "The west longitude can't be smaller than the east longitude");

  /// Create a new [LatLngBounds] from a list of [LatLng] points. This
  /// calculates the bounding box of the provided points.
  factory LatLngBounds.fromPoints(List<LatLng> points) {
    assert(
      points.isNotEmpty,
      'LatLngBounds cannot be created with an empty List of LatLng',
    );
    // initialize bounds with max values.
    double minX = 180;
    double maxX = -180;
    double minY = 90;
    double maxY = -90;
    // find the largest and smallest latitude and longitude
    for (final point in points) {
      if (point.longitude < minX) minX = point.longitude;
      if (point.longitude > maxX) maxX = point.longitude;
      if (point.latitude < minY) minY = point.latitude;
      if (point.latitude > maxY) maxY = point.latitude;
    }
    return LatLngBounds.unsafe(
      north: maxY,
      south: minY,
      east: maxX,
      west: minX,
    );
  }

  /// Expands bounding box by [latLng] coordinate point. This method mutates
  /// the bounds object on which it is called.
  void extend(LatLng latLng) {
    north = min(90, max(north, latLng.latitude));
    south = max(-90, min(south, latLng.latitude));
    east = min(180, max(east, latLng.longitude));
    west = max(-180, min(west, latLng.longitude));
  }

  /// Expands bounding box by other [bounds] object. If provided [bounds] object
  /// is smaller than current one, it is not shrunk. This method mutates
  /// the bounds object on which it is called.
  void extendBounds(LatLngBounds bounds) {
    north = min(90, max(north, bounds.north));
    south = max(-90, min(south, bounds.south));
    east = min(180, max(east, bounds.east));
    west = max(-180, min(west, bounds.west));
  }

  /// Obtain coordinates of southwest corner of the bounds.
  ///
  /// Instead of using latitude or longitude of the corner, use [south] or
  /// [west] instead!
  LatLng get southWest => LatLng(south, west);

  /// Obtain coordinates of northeast corner of the bounds.
  ///
  /// Instead of using latitude or longitude of the corner, use [north] or
  /// [east] instead!
  LatLng get northEast => LatLng(north, east);

  /// Obtain coordinates of northwest corner of the bounds.
  ///
  /// Instead of using latitude or longitude of the corner, use [north] or
  /// [west] instead!
  LatLng get northWest => LatLng(north, west);

  /// Obtain coordinates of southeast corner of the bounds.
  ///
  /// Instead of using latitude or longitude of the corner, use [south] or
  /// [east] instead!
  LatLng get southEast => LatLng(south, east);

  /// Obtain coordinates of the bounds center
  LatLng get center {
    // https://stackoverflow.com/a/4656937
    // http://www.movable-type.co.uk/scripts/latlong.html
    // coord 1: southWest
    // coord 2: northEast
    // phi: lat
    // lambda: lng

    final phi1 = south * degrees2Radians;
    final lambda1 = west * degrees2Radians;
    final phi2 = north * degrees2Radians;

    // delta lambda = lambda2-lambda1
    final dLambda = degrees2Radians * (east - west);

    final bx = cos(phi2) * cos(dLambda);
    final by = cos(phi2) * sin(dLambda);
    final phi3 = atan2(sin(phi1) + sin(phi2),
        sqrt((cos(phi1) + bx) * (cos(phi1) + bx) + by * by));
    final lambda3 = lambda1 + atan2(by, cos(phi1) + bx);

    // phi3 and lambda3 are actually in radians and LatLng wants degrees
    return LatLng(
      phi3 * radians2Degrees,
      (lambda3 * radians2Degrees + 540) % 360 - 180,
    );
  }

  /// Obtain simple coordinates of the bounds center
  LatLng get simpleCenter => LatLng((south + north) / 2, (east + west) / 2);

  /// Checks whether [point] is inside bounds
  bool contains(LatLng point) =>
      point.longitude >= west &&
      point.longitude <= east &&
      point.latitude >= south &&
      point.latitude <= north;

  /// Checks whether the [other] bounding box is contained inside bounds.
  bool containsBounds(LatLngBounds other) =>
      other.south >= south &&
      other.north <= north &&
      other.west >= west &&
      other.east <= east;

  /// Checks whether at least one edge of the [other] bounding box  is
  /// overlapping with this bounding box.
  ///
  /// Bounding boxes that touch each other but don't overlap are counted as
  /// not overlapping.
  bool isOverlapping(LatLngBounds other) => !(south > other.north ||
      north < other.south ||
      east < other.west ||
      west > other.east);

  @override
  int get hashCode => Object.hash(south, north, east, west);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LatLngBounds &&
          other.north == north &&
          other.south == south &&
          other.east == east &&
          other.west == west);

  @override
  String toString() =>
      'LatLngBounds(north: $north, south: $south, east: $east, west: $west)';
}
