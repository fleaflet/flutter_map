import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/geo/crs/crs.dart';
import 'package:latlong2/latlong.dart';

class FakeInfiniteCrs extends Crs {
  @override
  String get code => throw UnimplementedError();

  @override
  bool get infinite => true;

  @override
  Projection get projection => throw UnimplementedError();

  @override
  Transformation get transformation => throw UnimplementedError();

  @override
  (double, double)? get wrapLat => null;

  @override
  (double, double)? get wrapLng => null;

  /// Any projection just to get non-zero coordiantes.
  @override
  CustomPoint<double> latLngToPoint(LatLng latlng, double zoom) {
    return const Epsg3857().latLngToPoint(latlng, zoom);
  }
}
