import 'dart:math';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

@immutable
class FakeInfiniteCrs extends Crs {
  const FakeInfiniteCrs() : super(code: 'fake', infinite: true);

  @override
  Projection get projection => throw UnimplementedError();

  /// Any projection just to get non-zero coordiantes.
  @override
  (double, double) latLngToXY(LatLng latlng, double scale) =>
      const Epsg3857().latLngToXY(latlng, scale);

  @override
  (double, double) transform(double x, double y, double scale) =>
      const Epsg3857().transform(x, y, scale);

  @override
  (double, double) untransform(double x, double y, double scale) =>
      const Epsg3857().untransform(x, y, scale);

  @override
  LatLng pointToLatLng(Point point, double zoom) => throw UnimplementedError();

  @override
  Bounds<double>? getProjectedBounds(double zoom) => throw UnimplementedError();
}
