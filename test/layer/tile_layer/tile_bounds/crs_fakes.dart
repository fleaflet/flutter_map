import 'dart:math';

import 'package:flutter_map/src/geo/crs.dart';
import 'package:flutter_map/src/misc/bounds.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

@immutable
class FakeInfiniteCrs extends Crs {
  const FakeInfiniteCrs() : super(code: 'fake', infinite: true);

  @override
  Projection get projection => throw UnimplementedError();

  /// Any projection just to get non-zero coordiantes.
  @override
  Point<double> latLngToPoint(LatLng latlng, double zoom) {
    return const Epsg3857().latLngToPoint(latlng, zoom);
  }

  @override
  (double, double) latLngToXY(LatLng latlng, double scale) {
    return const Epsg3857().latLngToXY(latlng, scale);
  }

  @override
  LatLng pointToLatLng(Point point, double zoom) => throw UnimplementedError();

  @override
  Bounds<double>? getProjectedBounds(double zoom) => throw UnimplementedError();
}
