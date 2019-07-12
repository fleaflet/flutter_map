import 'dart:math';
import 'package:latlong/latlong.dart';
import 'package:tuple/tuple.dart';


const double PiOver180 = PI / 180.0;
double toDegrees(double radians) {
  return radians / PiOver180;
}

double toRadians(double degrees) {
  return degrees * PiOver180;
}


LatLng calculateEndingGlobalCoordinates(LatLng start, double startBearing, double distance) {
  double mSemiMajorAxis = 6378137.0; //WGS84 major axis
  double mSemiMinorAxis = (1.0 - 1.0 / 298.257223563) * 6378137.0;
  double mFlattening = 1.0 / 298.257223563;
  // double mInverseFlattening = 298.257223563;

  double a = mSemiMajorAxis;
  double b = mSemiMinorAxis;
  double aSquared = a * a;
  double bSquared = b * b;
  double f = mFlattening;
  double phi1 = toRadians(start.latitude);
  double alpha1 = toRadians(startBearing);
  double cosAlpha1 = cos(alpha1);
  double sinAlpha1 = sin(alpha1);
  double s = distance;
  double tanU1 = (1.0 - f) * tan(phi1);
  double cosU1 = 1.0 / sqrt(1.0 + tanU1 * tanU1);
  double sinU1 = tanU1 * cosU1;

  // eq. 1
  double sigma1 = atan2(tanU1, cosAlpha1);

  // eq. 2
  double sinAlpha = cosU1 * sinAlpha1;

  double sin2Alpha = sinAlpha * sinAlpha;
  double cos2Alpha = 1 - sin2Alpha;
  double uSquared = cos2Alpha * (aSquared - bSquared) / bSquared;

  // eq. 3
  double A = 1 + (uSquared / 16384) * (4096 + uSquared * (-768 + uSquared * (320 - 175 * uSquared)));

  // eq. 4
  double B = (uSquared / 1024) * (256 + uSquared * (-128 + uSquared * (74 - 47 * uSquared)));

  // iterate until there is a negligible change in sigma
  double deltaSigma;
  double sOverbA = s / (b * A);
  double sigma = sOverbA;
  double sinSigma;
  double prevSigma = sOverbA;
  double sigmaM2;
  double cosSigmaM2;
  double cos2SigmaM2;

  for (;;) {
    // eq. 5
    sigmaM2 = 2.0 * sigma1 + sigma;
    cosSigmaM2 = cos(sigmaM2);
    cos2SigmaM2 = cosSigmaM2 * cosSigmaM2;
    sinSigma = sin(sigma);
    double cosSignma = cos(sigma);

    // eq. 6
    deltaSigma = B *
        sinSigma *
        (cosSigmaM2 +
            (B / 4.0) *
                (cosSignma * (-1 + 2 * cos2SigmaM2) -
                    (B / 6.0) * cosSigmaM2 * (-3 + 4 * sinSigma * sinSigma) * (-3 + 4 * cos2SigmaM2)));

    // eq. 7
    sigma = sOverbA + deltaSigma;

    // break after converging to tolerance
    if ((sigma - prevSigma).abs() < 0.0000000000001) break;

    prevSigma = sigma;
  }

  sigmaM2 = 2.0 * sigma1 + sigma;
  cosSigmaM2 = cos(sigmaM2);
  cos2SigmaM2 = cosSigmaM2 * cosSigmaM2;

  double cosSigma = cos(sigma);
  sinSigma = sin(sigma);

  // eq. 8
  double phi2 = atan2(sinU1 * cosSigma + cosU1 * sinSigma * cosAlpha1,
      (1.0 - f) * sqrt(sin2Alpha + pow(sinU1 * sinSigma - cosU1 * cosSigma * cosAlpha1, 2.0)));

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
  double lambda = atan2(sinSigma * sinAlpha1, (cosU1 * cosSigma - sinU1 * sinSigma * cosAlpha1));

  // eq. 10
  double C = (f / 16) * cos2Alpha * (4 + f * (4 - 3 * cos2Alpha));

  // eq. 11
  double L = lambda - (1 - C) * f * sinAlpha * (sigma + C * sinSigma * (cosSigmaM2 + C * cosSigma * (-1 + 2 * cos2SigmaM2)));

  // eq. 12
  // double alpha2 = Math.atan2(sinAlpha, -sinU1 * sinSigma + cosU1 *
  // cosSigma * cosAlpha1);

  // build result
  double latitude = toDegrees(phi2);
  double longitude = start.longitude + toDegrees(L);

  // if ((endBearing != null) && (endBearing.length > 0)) {
  // endBearing[0] = toDegrees(alpha2);
  // }

  latitude = latitude < -90 ? -90 : latitude;
  latitude = latitude > 90 ? 90 : latitude;
  longitude = longitude < -180 ? -180 : longitude;
  longitude = longitude > 180 ? 180 : longitude;
  return new LatLng(latitude, longitude);
}
