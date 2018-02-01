import 'dart:math' as math;
import 'package:latlong/latlong.dart';

class LatLngBounds {
  LatLng sw;
  LatLng ne;
  LatLngBounds(LatLng corner1, LatLng corner2) {
    extend(corner1);
    extend(corner2);
  }

  void extend(LatLng latlng) {
    _extend(latlng, latlng);
  }

  void extendBounds(LatLngBounds bounds) {
    _extend(bounds.sw, bounds.ne);
  }

  void _extend(LatLng sw2, LatLng ne2) {
    if (sw == null && ne == null) {
      sw = new LatLng(sw2.latitude, sw2.longitude);
      ne = new LatLng(ne2.latitude, ne2.longitude);
    } else {
      sw.latitude = math.min(sw2.latitude, sw.latitude);
      sw.longitude = math.min(sw2.longitude, sw.longitude);
      ne.latitude = math.max(ne2.latitude, ne.latitude);
      ne.longitude = math.max(ne2.longitude, ne.longitude);
    }
  }
}
