import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Data structure representing rectangular bounding box constrained by its
/// northwest and southeast corners
class LatLngBounds {
  LatLng? _sw;
  LatLng? _ne;

  LatLngBounds([LatLng? corner1, LatLng? corner2]) {
    extend(corner1);
    extend(corner2);
  }

  LatLngBounds.fromPoints(List<LatLng> points) {
    if (points.isNotEmpty) {
      num? minX;
      num? maxX;
      num? minY;
      num? maxY;

      for (var point in points) {
        num x = point.longitudeInRad;
        num y = point.latitudeInRad;

        if (minX == null || minX > x) {
          minX = x;
        }

        if (minY == null || minY > y) {
          minY = y;
        }

        if (maxX == null || maxX < x) {
          maxX = x;
        }

        if (maxY == null || maxY < y) {
          maxY = y;
        }
      }

      _sw = LatLng(radianToDeg(minY as double), radianToDeg(minX as double));
      _ne = LatLng(radianToDeg(maxY as double), radianToDeg(maxX as double));
    }
  }

  /// Expands bounding box by [latlng] coordinate point. This method mutates
  /// the bounds object on which it is called.
  void extend(LatLng? latlng) {
    if (latlng == null) {
      return;
    }
    _extend(latlng, latlng);
  }

  /// Expands bounding box by other [bounds] object. If provided [bounds] object
  /// is smaller than current one, it is not shrunk. This method mutates
  /// the bounds object on which it is called.
  void extendBounds(LatLngBounds bounds) {
    _extend(bounds._sw, bounds._ne);
  }

  void _extend(LatLng? sw2, LatLng? ne2) {
    if (_sw == null && _ne == null) {
      _sw = LatLng(sw2!.latitude, sw2.longitude);
      _ne = LatLng(ne2!.latitude, ne2.longitude);
    } else {
      _sw!.latitude = math.min(sw2!.latitude, _sw!.latitude);
      _sw!.longitude = math.min(sw2.longitude, _sw!.longitude);
      _ne!.latitude = math.max(ne2!.latitude, _ne!.latitude);
      _ne!.longitude = math.max(ne2.longitude, _ne!.longitude);
    }
  }

  /// Obtain west edge of the bounds
  double get west => southWest!.longitude;

  /// Obtain south edge of the bounds
  double get south => southWest!.latitude;

  /// Obtain east edge of the bounds
  double get east => northEast!.longitude;

  /// Obtain north edge of the bounds
  double get north => northEast!.latitude;

  /// Obtain coordinates of southwest corner of the bounds
  LatLng? get southWest => _sw;

  /// Obtain coordinates of northeast corner of the bounds
  LatLng? get northEast => _ne;

  /// Obtain coordinates of northwest corner of the bounds
  LatLng get northWest => LatLng(north, west);

  /// Obtain coordinates of southeast corner of the bounds
  LatLng get southEast => LatLng(south, east);

  /// Obtain coordinates of the bounds center
  LatLng get center {
    /* https://stackoverflow.com/a/4656937
       http://www.movable-type.co.uk/scripts/latlong.html

       coord 1: southWest
       coord 2: northEast

       phi: lat
       lambda: lng
    */

    var phi1 = southWest!.latitudeInRad;
    var lambda1 = southWest!.longitudeInRad;
    var phi2 = northEast!.latitudeInRad;

    var dLambda = degToRadian(northEast!.longitude -
        southWest!.longitude); // delta lambda = lambda2-lambda1

    var bx = math.cos(phi2) * math.cos(dLambda);
    var by = math.cos(phi2) * math.sin(dLambda);
    var phi3 = math.atan2(math.sin(phi1) + math.sin(phi2),
        math.sqrt((math.cos(phi1) + bx) * (math.cos(phi1) + bx) + by * by));
    var lambda3 = lambda1 + math.atan2(by, math.cos(phi1) + bx);

    // phi3 and lambda3 are actually in radians and LatLng wants degrees
    return LatLng(radianToDeg(phi3), radianToDeg(lambda3));
  }

  /// Checks whether bound object is valid
  bool get isValid {
    return _sw != null && _ne != null;
  }

  /// Checks whether [point] is inside bounds
  bool contains(LatLng? point) {
    if (!isValid) {
      return false;
    }
    var sw2 = point;
    var ne2 = point;
    return containsBounds(LatLngBounds(sw2, ne2));
  }

  /// Checks whether [bounds] is contained inside bounds
  bool containsBounds(LatLngBounds bounds) {
    var sw2 = bounds._sw!;
    var ne2 = bounds._ne;
    return (sw2.latitude >= _sw!.latitude) &&
        (ne2!.latitude <= _ne!.latitude) &&
        (sw2.longitude >= _sw!.longitude) &&
        (ne2.longitude <= _ne!.longitude);
  }

  /// Checks whether at least one edge of [bounds] is overlapping with some
  /// other edge of bounds
  bool isOverlapping(LatLngBounds? bounds) {
    if (!isValid) {
      return false;
    }
    /* check if bounding box rectangle is outside the other, if it is then it's
       considered not overlapping
    */
    if (_sw!.latitude > bounds!._ne!.latitude ||
        _ne!.latitude < bounds._sw!.latitude ||
        _ne!.longitude < bounds._sw!.longitude ||
        _sw!.longitude > bounds._ne!.longitude) {
      return false;
    }
    return true;
  }

  /// Expands bounds by decimal degrees unlike [extend] or [extendBounds]
  void pad(double bufferRatio) {
    var heightBuffer = (_sw!.latitude - _ne!.latitude).abs() * bufferRatio;
    var widthBuffer = (_sw!.longitude - _ne!.longitude).abs() * bufferRatio;

    _sw = LatLng(_sw!.latitude - heightBuffer, _sw!.longitude - widthBuffer);
    _ne = LatLng(_ne!.latitude + heightBuffer, _ne!.longitude + widthBuffer);
  }

  @override
  int get hashCode => _sw.hashCode + _ne.hashCode;

  @override
  bool operator ==(Object other) =>
      other is LatLngBounds && other._sw == _sw && other._ne == _ne;
}
