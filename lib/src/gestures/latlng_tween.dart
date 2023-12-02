import 'package:flutter/animation.dart';
import 'package:flutter_map/src/geo/latlng.dart';

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end})
      : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) => (
        lat: begin!.lat + (end!.lat - begin!.lat) * t,
        lon: begin!.lon + (end!.lon - begin!.lon) * t,
      );
}
