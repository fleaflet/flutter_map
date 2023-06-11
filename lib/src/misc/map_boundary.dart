import 'dart:ui';

import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map/src/map/map_safe_area.dart';
import 'package:latlong2/latlong.dart';

sealed class MapBoundary {
  const MapBoundary();
}

class FixedBoundary extends MapBoundary {
  final LatLngBounds latLngBounds;

  const FixedBoundary({
    required this.latLngBounds,
  });

  bool contains(LatLng latLng) => latLngBounds.contains(latLng);

  LatLng clamp(LatLng latLng) => LatLng(
        latLng.latitude.clamp(latLngBounds.south, latLngBounds.north),
        latLng.longitude.clamp(latLngBounds.west, latLngBounds.east),
      );
}

class AdaptiveBoundary extends MapBoundary {
  final Size screenSize;
  final LatLngBounds latLngBounds;
  MapSafeArea? _mapSafeAreaCache;

  /// Tiles outside of these bounds will never be displayed.
  AdaptiveBoundary({
    required this.screenSize,
    required this.latLngBounds,
  });

  bool contains(LatLng latLng, double zoom) =>
      _mapSafeArea(zoom).contains(latLng);

  LatLng clampWithFallback(LatLng latLng, LatLng fallback, double zoom) =>
      _mapSafeArea(zoom).clampWithFallback(latLng, fallback);

  MapSafeArea _mapSafeArea(double zoom) {
    if (_mapSafeAreaCache?.zoom != zoom) {
      return MapSafeArea(
        screenSize: screenSize,
        bounds: latLngBounds,
        zoom: zoom,
      );
    }

    return _mapSafeAreaCache!;
  }

  @override
  bool operator ==(Object other) {
    return other is AdaptiveBoundary &&
        other.screenSize == screenSize &&
        other.latLngBounds == latLngBounds;
  }

  @override
  int get hashCode => Object.hash(screenSize, latLngBounds);
}
