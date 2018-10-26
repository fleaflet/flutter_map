import 'dart:math';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/src/core/util.dart';

class LocationUtils {
  /// Computes if the given point is in the path of the polyline.
  /// * [point] to evalute in the polyline.
  /// * [linePoints] the points of the polyline.
  /// * [toleratedDistance] the distance tolerated from the point to the line.
  static bool isPointInPolyline(
    LatLng point,
    List<LatLng> linePoints, {
    double toleratedDistance = 0.1,
  }) {
    double distance = 0.0;
    if (linePoints.isNotEmpty) {
      if (linePoints.length > 2) {
        List<List<LatLng>> list = [];
        for (int i = 0; i < linePoints.length - 1; i++) {
          list.add([linePoints[i], linePoints[(i + 1)]]);
        }
        for (var sublist in list) {
          LatLng vertex1 = sublist[0];
          LatLng vertex2 = sublist[1];
          double distanceToLine =
              LocationUtils.distanceToLine(point, vertex1, vertex2);
          distance = (distance == 0.0)
              ? distanceToLine
              : (distanceToLine < distance ? distanceToLine : distance);
          if (distance <= toleratedDistance) {
            return true;
          }
        }
      } else if (linePoints.length == 1) {
        distance = LocationUtils.distanceBetween(linePoints[0], point);
        if (distance <= toleratedDistance) {
          return true;
        }
      }
    }
    return false;
  }

  /// Calculates the nearest point in a line represented by ([vertexA], [vertexB])
  /// from a [point] and Returns the distance in meters between the line and the [point].
  static double distanceToLine(
      final LatLng point, final LatLng vertexA, final LatLng vertexB) {
    if (vertexA == vertexB) {
      return distanceBetween(vertexB, point);
    }
    final double s0lat = degToRadian(point.latitude);
    final double s0lng = degToRadian(point.longitude);
    final double s1lat = degToRadian(vertexA.latitude);
    final double s1lng = degToRadian(vertexA.longitude);
    final double s2lat = degToRadian(vertexB.latitude);
    final double s2lng = degToRadian(vertexB.longitude);

    double s2s1lat = s2lat - s1lat;
    double s2s1lng = s2lng - s1lng;
    final double u = ((s0lat - s1lat) * s2s1lat + (s0lng - s1lng) * s2s1lng) /
        (s2s1lat * s2s1lat + s2s1lng * s2s1lng);
    if (u <= 0) {
      return distanceBetween(point, vertexA);
    }
    if (u >= 1) {
      return distanceBetween(point, vertexB);
    }
    LatLng sa = LatLng(
      (point.latitude - vertexA.latitude),
      (point.longitude - vertexA.longitude),
    );
    LatLng sb = LatLng(
      (u * (vertexB.latitude - vertexA.latitude)),
      (u * (vertexB.longitude - vertexA.longitude)),
    );
    return distanceBetween(sa, sb);
  }

  /// Computes the distance between two points.
  /// * [pointA] first point.
  /// * [pointB] second point.
  ///
  /// Returns the distance between the points in meters.
  ///
  /// Transcribed to dartlang from PolyUtil.java from android-maps-utils library by Google.
  /// https://github.com/googlemaps/android-maps-utils
  static double distanceBetween(LatLng pointA, LatLng pointB) {
    int maximeters = 20;
    // Convert lat/long to radians
    double lat1 = pointA.latitude;
    double lon1 = pointA.longitude;
    double lat2 = pointB.latitude;
    double lon2 = pointB.longitude;
    lat1 *= pi / 180.0;
    lat2 *= pi / 180.0;
    lon1 *= pi / 180.0;
    lon2 *= pi / 180.0;
    double a = 6378137.0; // WGS84 major axis
    double b = 6356752.3142; // WGS84 semi-major axis
    double f = (a - b) / a;
    double aSqMinusBSqOverBSq = (a * a - b * b) / (b * b);
    double L = lon2 - lon1;
    double A = 0.0;
    double u1 = atan((1.0 - f) * tan(lat1));
    double u2 = atan((1.0 - f) * tan(lat2));
    double cosU1 = cos(u1);
    double cosU2 = cos(u2);
    double sinU1 = sin(u1);
    double sinU2 = sin(u2);
    double cosU1cosU2 = cosU1 * cosU2;
    double sinU1sinU2 = sinU1 * sinU2;
    double sigma = 0.0;
    double deltaSigma = 0.0;
    double cosSqAlpha = 0.0;
    double cos2SM = 0.0;
    double cosSigma = 0.0;
    double sinSigma = 0.0;
    double cosLambda = 0.0;
    double sinLambda = 0.0;
    double lambda = L; // initial guess
    for (int iter = 0; iter < maximeters; iter++) {
      double lambdaOrig = lambda;
      cosLambda = cos(lambda);
      sinLambda = sin(lambda);
      double t1 = cosU2 * sinLambda;
      double t2 = cosU1 * sinU2 - sinU1 * cosU2 * cosLambda;
      double sinSqSigma = t1 * t1 + t2 * t2; // (14)
      sinSigma = sqrt(sinSqSigma);
      cosSigma = sinU1sinU2 + cosU1cosU2 * cosLambda; // (15)
      sigma = atan2(sinSigma, cosSigma); // (16)
      double sinAlpha =
          (sinSigma == 0) ? 0.0 : cosU1cosU2 * sinLambda / sinSigma; // (17)
      cosSqAlpha = 1.0 - sinAlpha * sinAlpha;
      cos2SM = (cosSqAlpha == 0)
          ? 0.0
          : cosSigma - 2.0 * sinU1sinU2 / cosSqAlpha; // (18)
      double uSquared = cosSqAlpha * aSqMinusBSqOverBSq; // defn
      A = 1 +
          (uSquared / 16384.0) * // (3)
              (4096.0 +
                  uSquared * (-768 + uSquared * (320.0 - 175.0 * uSquared)));
      double B = (uSquared / 1024.0) * // (4)
          (256.0 + uSquared * (-128.0 + uSquared * (74.0 - 47.0 * uSquared)));
      double C = (f / 16.0) *
          cosSqAlpha *
          (4.0 + f * (4.0 - 3.0 * cosSqAlpha)); // (10)
      double cos2SMSq = cos2SM * cos2SM;
      deltaSigma = B *
          sinSigma * // (6)
          (cos2SM +
              (B / 4.0) *
                  (cosSigma * (-1.0 + 2.0 * cos2SMSq) -
                      (B / 6.0) *
                          cos2SM *
                          (-3.0 + 4.0 * sinSigma * sinSigma) *
                          (-3.0 + 4.0 * cos2SMSq)));
      lambda = L +
          (1.0 - C) *
              f *
              sinAlpha *
              (sigma +
                  C *
                      sinSigma *
                      (cos2SM +
                          C *
                              cosSigma *
                              (-1.0 + 2.0 * cos2SM * cos2SM))); // (11)
      double delta = (lambda - lambdaOrig) / lambda;
      if (delta.abs() < 1.0e-12) {
        break;
      }
    }
    double distance = (b * A * (sigma - deltaSigma));
    return distance;
  }

  /// Computes whether the given point lies inside the specified polygon.
  /// The polygon is always considered closed, regardless of whether the last point equals
  /// the first or not.
  /// Inside is defined as not containing the South Pole -- the South Pole is always outside.
  /// The polygon is formed of great circle segments if [geodesic] is true, and of rhumb
  /// (loxodromic) segments otherwise.
  ///
  /// Transcribed to dartlang from PolyUtil.java from android-maps-utils library by Google.
  /// https://github.com/googlemaps/android-maps-utils
  static bool containsLocation(
    double latitude,
    double longitude,
    List<LatLng> polygon, {
    bool geodesic = true,
  }) {
    final int size = polygon.length;
    if (size == 0) {
      return false;
    }
    double lat3 = degToRadian(latitude);
    double lng3 = degToRadian(longitude);
    LatLng prev = polygon[size - 1];
    double lat1 = degToRadian(prev.latitude);
    double lng1 = degToRadian(prev.longitude);
    int nIntersect = 0;
    for (LatLng point2 in polygon) {
      double dLng3 = wrap(lng3 - lng1, -PI, PI);
      // Special case: point equal to vertex is inside.
      if (lat3 == lat1 && dLng3 == 0) {
        return true;
      }
      double lat2 = degToRadian(point2.latitude);
      double lng2 = degToRadian(point2.longitude);
      // Offset longitudes by -lng1.
      if (intersects(lat1, lat2, wrap(lng2 - lng1, -PI, PI), lat3, dLng3,
          geodesic: geodesic)) {
        ++nIntersect;
      }
      lat1 = lat2;
      lng1 = lng2;
    }
    return (nIntersect & 1) != 0;
  }

  /// Computes whether the vertical segment (lat3, lng3) to South Pole intersects the segment
  /// (lat1, lng1) to (lat2, lng2).
  /// Longitudes are offset by -lng1; the implicit lng1 becomes 0.
  ///
  /// Transcribed to dartlang from PolyUtil.java from android-maps-utils library by Google.
  /// https://github.com/googlemaps/android-maps-utils
  static bool intersects(
    double lat1,
    double lat2,
    double lng2,
    double lat3,
    double lng3, {
    bool geodesic = true,
  }) {
    // Both ends on the same side of lng3.
    if ((lng3 >= 0 && lng3 >= lng2) || (lng3 < 0 && lng3 < lng2)) {
      return false;
    }
    // Point is South Pole.
    if (lat3 <= -PI / 2) {
      return false;
    }
    // Any segment end is a pole.
    if (lat1 <= -PI / 2 ||
        lat2 <= -PI / 2 ||
        lat1 >= PI / 2 ||
        lat2 >= PI / 2) {
      return false;
    }
    if (lng2 <= -PI) {
      return false;
    }
    double linearLat = (lat1 * (lng2 - lng3) + lat2 * lng3) / lng2;
    // Northern hemisphere and point under lat-lng line.
    if (lat1 >= 0 && lat2 >= 0 && lat3 < linearLat) {
      return false;
    }
    // Southern hemisphere and point above lat-lng line.
    if (lat1 <= 0 && lat2 <= 0 && lat3 >= linearLat) {
      return true;
    }
    // North Pole.
    if (lat3 >= PI / 2) {
      return true;
    }
    // Compare lat3 with latitude on the GC/Rhumb segment corresponding to lng3.
    // Compare through a strictly-increasing function (tan() or mercator()) as convenient.
    return geodesic
        ? tan(lat3) >= tanLatGC(lat1, lat2, lng2, lng3)
        : mercator(lat3) >= mercatorLatRhumb(lat1, lat2, lng2, lng3);
  }

  /// Returns the LatLng resulting from moving a distance from an origin
  /// in the specified heading (expressed in degrees clockwise from north).
  /// * [from]     The LatLng from which to start.
  /// * [distance] The distance to travel.
  /// * [heading]  The heading in degrees clockwise from north.
  static LatLng computeOffset(LatLng from, double distance, double heading) {
    distance /= EARTH_RADIUS;
    heading = degToRadian(heading);
    // http://williams.best.vwh.net/avform.htm#LL
    double fromLat = degToRadian(from.latitude);
    double fromLng = degToRadian(from.longitude);
    double cosDistance = cos(distance);
    double sinDistance = sin(distance);
    double sinFromLat = sin(fromLat);
    double cosFromLat = cos(fromLat);
    double sinLat =
        cosDistance * sinFromLat + sinDistance * cosFromLat * cos(heading);
    double dLng = atan2(sinDistance * cosFromLat * sin(heading),
        cosDistance - sinFromLat * sinLat);
    return LatLng(radianToDeg(asin(sinLat)), radianToDeg(fromLng + dLng));
  }

  static double computeHeading(LatLng pointA, LatLng pointB) {
    var y = sin(pointB.longitudeInRad - pointA.longitudeInRad) *
        cos(pointB.latitudeInRad);
    var x = cos(pointA.latitudeInRad) * sin(pointB.latitudeInRad) -
        sin(pointA.latitudeInRad) *
            cos(pointB.latitudeInRad) *
            cos(pointB.longitudeInRad - pointA.longitudeInRad);
    return radianToDeg(atan2(y, x));
  }

  /// Returns tan(latitude-at-lng3) on the great circle (lat1, lng1) to (lat2, lng2). lng1==0.
  /// See http://williams.best.vwh.net/avform.htm .
  ///
  /// Transcribed to dartlang from PolyUtil.java from android-maps-utils library by Google.
  /// https://github.com/googlemaps/android-maps-utils
  static double tanLatGC(double lat1, double lat2, double lng2, double lng3) {
    return (tan(lat1) * sin(lng2 - lng3) + tan(lat2) * sin(lng3)) / sin(lng2);
  }

  /// Returns mercator(latitude-at-lng3) on the Rhumb line (lat1, lng1) to (lat2, lng2). lng1==0.
  ///
  /// Transcribed to dartlang from PolyUtil.java from android-maps-utils library by Google.
  /// https://github.com/googlemaps/android-maps-utils
  static double mercatorLatRhumb(
      double lat1, double lat2, double lng2, double lng3) {
    return (mercator(lat1) * (lng2 - lng3) + mercator(lat2) * lng3) / lng2;
  }

  /// Rotates a point to a determinate amount of degrees clockwise.
  /// * [center] Observation point to rotate the target from.
  /// * [pointToRotate] Point that will be rotated.
  /// * [degrees] Amount of degrees.
  static LatLng rotateLatLng(
      LatLng center, LatLng pointToRotate, double degrees) {
    var xRot = center.longitude +
        cos(degToRadian(degrees)) *
            (pointToRotate.longitude - center.longitude) -
        sin(degToRadian(degrees)) * (pointToRotate.latitude - center.latitude);
    var yRot = center.latitude +
        sin(degToRadian(degrees)) *
            (pointToRotate.longitude - center.longitude) +
        cos(degToRadian(degrees)) * (pointToRotate.latitude - center.latitude);
    return LatLng(yRot, xRot);
  }
}
