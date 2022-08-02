import 'dart:math';

import 'package:latlong2/latlong.dart';

const double piOver180 = pi / 180.0;
double toDegrees(double radians) {
  return radians / piOver180;
}

double toRadians(double degrees) {
  return degrees * piOver180;
}

LatLng calculateEndingGlobalCoordinates(
    LatLng start, double startBearing, double distance) {
  const mSemiMajorAxis = 6378137.0; //WGS84 major axis
  const mSemiMinorAxis = (1.0 - 1.0 / 298.257223563) * 6378137.0;
  const mFlattening = 1.0 / 298.257223563;
  // double mInverseFlattening = 298.257223563;

  const a = mSemiMajorAxis;
  const b = mSemiMinorAxis;
  const aSquared = a * a;
  const bSquared = b * b;
  const f = mFlattening;
  final phi1 = toRadians(start.latitude);
  final alpha1 = toRadians(startBearing);
  final cosAlpha1 = cos(alpha1);
  final sinAlpha1 = sin(alpha1);
  final s = distance;
  final tanU1 = (1.0 - f) * tan(phi1);
  final cosU1 = 1.0 / sqrt(1.0 + tanU1 * tanU1);
  final sinU1 = tanU1 * cosU1;

  // eq. 1
  final sigma1 = atan2(tanU1, cosAlpha1);

  // eq. 2
  final sinAlpha = cosU1 * sinAlpha1;

  final sin2Alpha = sinAlpha * sinAlpha;
  final cos2Alpha = 1 - sin2Alpha;
  final uSquared = cos2Alpha * (aSquared - bSquared) / bSquared;

  // eq. 3
  final A = 1 +
      (uSquared / 16384) *
          (4096 + uSquared * (-768 + uSquared * (320 - 175 * uSquared)));

  // eq. 4
  final B = (uSquared / 1024) *
      (256 + uSquared * (-128 + uSquared * (74 - 47 * uSquared)));

  // iterate until there is a negligible change in sigma
  double deltaSigma;
  final sOverbA = s / (b * A);
  var sigma = sOverbA;
  double sinSigma;
  var prevSigma = sOverbA;
  double sigmaM2;
  double cosSigmaM2;
  double cos2SigmaM2;

  for (;;) {
    // eq. 5
    sigmaM2 = 2.0 * sigma1 + sigma;
    cosSigmaM2 = cos(sigmaM2);
    cos2SigmaM2 = cosSigmaM2 * cosSigmaM2;
    sinSigma = sin(sigma);
    final cosSignma = cos(sigma);

    // eq. 6
    deltaSigma = B *
        sinSigma *
        (cosSigmaM2 +
            (B / 4.0) *
                (cosSignma * (-1 + 2 * cos2SigmaM2) -
                    (B / 6.0) *
                        cosSigmaM2 *
                        (-3 + 4 * sinSigma * sinSigma) *
                        (-3 + 4 * cos2SigmaM2)));

    // eq. 7
    sigma = sOverbA + deltaSigma;

    // break after converging to tolerance
    if ((sigma - prevSigma).abs() < 0.0000000000001) break;

    prevSigma = sigma;
  }

  sigmaM2 = 2.0 * sigma1 + sigma;
  cosSigmaM2 = cos(sigmaM2);
  cos2SigmaM2 = cosSigmaM2 * cosSigmaM2;

  final cosSigma = cos(sigma);
  sinSigma = sin(sigma);

  // eq. 8
  final phi2 = atan2(
      sinU1 * cosSigma + cosU1 * sinSigma * cosAlpha1,
      (1.0 - f) *
          sqrt(sin2Alpha +
              pow(sinU1 * sinSigma - cosU1 * cosSigma * cosAlpha1, 2.0)));

  // eq. 9
  // This fixes the pole crossing defect spotted by Matt Feemster. When a
  // path passes a pole and essentially crosses a line of latitude twice -
  // once in each direction - the longitude calculation got messed up.
  // Using
  // atan2 instead of atan fixes the defect. The change is in the next 3
  // lines.
  // double tanLambda = sinSigma * sinAlpha1 / (cosU1 * cosSigma - sinU1 *
  // sinSigma * cosAlpha1);
  // double lambda = Math.atan(tanLambda);
  final lambda = atan2(
      sinSigma * sinAlpha1, (cosU1 * cosSigma - sinU1 * sinSigma * cosAlpha1));

  // eq. 10
  final C = (f / 16) * cos2Alpha * (4 + f * (4 - 3 * cos2Alpha));

  // eq. 11
  final L = lambda -
      (1 - C) *
          f *
          sinAlpha *
          (sigma +
              C *
                  sinSigma *
                  (cosSigmaM2 + C * cosSigma * (-1 + 2 * cos2SigmaM2)));

  // eq. 12
  // double alpha2 = Math.atan2(sinAlpha, -sinU1 * sinSigma + cosU1 *
  // cosSigma * cosAlpha1);

  // build result
  var latitude = toDegrees(phi2);
  var longitude = start.longitude + toDegrees(L);

  // if ((endBearing != null) && (endBearing.length > 0)) {
  // endBearing[0] = toDegrees(alpha2);
  // }

  latitude = latitude < -90 ? -90 : latitude;
  latitude = latitude > 90 ? 90 : latitude;
  longitude = longitude < -180 ? -180 : longitude;
  longitude = longitude > 180 ? 180 : longitude;
  return LatLng(latitude, longitude);
}
