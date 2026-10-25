import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

const _center = LatLng(45.5, -122.6);

MapCamera _camera({double pitch = 0, double rotation = 0, double zoom = 10}) =>
    MapCamera(
      crs: const Epsg3857(),
      center: _center,
      zoom: zoom,
      rotation: rotation,
      pitch: pitch,
      nonRotatedSize: const Size(400, 600),
    );

// About 730 x 1040 projected px at zoom 10: larger than the rotated viewport,
// smaller than the ground visible at pitch 60.
final _bounds = LatLngBounds(
  LatLng(_center.latitude - 0.5, _center.longitude - 0.5),
  LatLng(_center.latitude + 0.5, _center.longitude + 0.5),
);

/// The smallest distance from [positions] to the edges of [area], negative if
/// a position is outside it.
double _margin(Iterable<Offset> positions, Rect area) => positions
    .map((p) => [
          p.dx - area.left,
          area.right - p.dx,
          p.dy - area.top,
          area.bottom - p.dy,
        ].reduce(math.min))
    .reduce(math.min);

Iterable<Offset> _screen(MapCamera camera, List<LatLng> points) =>
    points.map(camera.latLngToScreenOffset);

final _corners = [
  _bounds.northWest,
  _bounds.northEast,
  _bounds.southEast,
  _bounds.southWest,
];

final _coordinates = [
  const LatLng(45.40, -122.75),
  const LatLng(45.62, -122.70),
  const LatLng(45.55, -122.45),
  const LatLng(45.45, -122.50),
  const LatLng(45.50, -122.60),
];

void main() {
  group('contain constraints when pitched', () {
    for (final (name, constraint) in [
      ('contain', CameraConstraint.contain(bounds: _bounds)),
      (
        'containLatitude',
        CameraConstraint.containLatitude(_bounds.south, _bounds.north),
      ),
    ]) {
      test('$name accepts a pitch change inside the bounds', () {
        final camera = _camera(pitch: 60, rotation: 30);
        final constrained = constraint.constrain(camera);
        expect(constrained, isNotNull);
        expect(constrained!.center, _center);
        expect(constrained.pitch, 60);
      });

      test('$name constrains the center independently of the pitch', () {
        final beyond = LatLng(_center.latitude + 2, _center.longitude + 2);
        MapCamera constrained(double pitch) => constraint.constrain(
              _camera(pitch: pitch, rotation: 30).withPosition(center: beyond),
            )!;
        expect(constrained(60).center, constrained(0).center);
        expect(constrained(60).center, isNot(beyond));
      });
    }
  });

  group('camera fit when pitched', () {
    const viewport = Rect.fromLTWH(0, 0, 400, 600);

    test('fit bounds', () {
      final fitted = CameraFit.bounds(bounds: _bounds)
          .fit(_camera(pitch: 60, rotation: 30));
      expect(fitted.pitch, 60);
      expect(fitted.rotation, 30);
      final margin = _margin(_screen(fitted, _corners), viewport);
      expect(margin, greaterThan(-0.01));
      expect(margin, lessThan(1));
    });

    test('fit coordinates with padding', () {
      final fitted = CameraFit.coordinates(
        coordinates: _coordinates,
        padding: const EdgeInsets.all(20),
      ).fit(_camera(pitch: 45));
      final margin = _margin(_screen(fitted, _coordinates), viewport);
      expect(margin, greaterThan(20 - 0.01));
      expect(margin, lessThan(21));
    });

    test('maximum zoom keeps the coordinates inside', () {
      final unlimited = CameraFit.coordinates(coordinates: _coordinates)
          .fit(_camera(pitch: 60, rotation: 30));
      final fitted = CameraFit.coordinates(
        coordinates: _coordinates,
        maxZoom: unlimited.zoom - 0.5,
      ).fit(_camera(pitch: 60, rotation: 30));
      expect(fitted.zoom, closeTo(unlimited.zoom - 0.5, 1e-9));
      expect(
        _margin(_screen(fitted, _coordinates), viewport),
        greaterThan(-0.01),
      );
    });

    test('integer zoom keeps the bounds inside', () {
      final fitted = CameraFit.bounds(
        bounds: _bounds,
        forceIntegerZoomLevel: true,
      ).fit(_camera(pitch: 60, rotation: 30));
      expect(fitted.zoom, fitted.zoom.roundToDouble());
      expect(_margin(_screen(fitted, _corners), viewport), greaterThan(-0.01));
    });

    test('fit inside bounds', () {
      final fitted = CameraFit.insideBounds(bounds: _bounds)
          .fit(_camera(pitch: 60, rotation: 30));
      final projectedBounds = Rect.fromPoints(
        fitted.projectAtZoom(_bounds.southEast),
        fitted.projectAtZoom(_bounds.northWest),
      );
      final ground = [
        viewport.topLeft,
        viewport.topRight,
        viewport.bottomRight,
        viewport.bottomLeft,
      ].map((corner) =>
          fitted.projectAtZoom(fitted.screenOffsetToLatLng(corner)));
      final margin = _margin(ground, projectedBounds);
      expect(margin, greaterThan(-0.01));
      expect(margin, lessThan(1));
    });

    test('fit a single coordinate', () {
      const coordinate = LatLng(45.6, -122.5);
      MapCamera fit(double pitch) => const CameraFit.coordinates(
            coordinates: [coordinate],
            maxZoom: 16,
          ).fit(_camera(pitch: pitch, rotation: 30));
      final fitted = fit(60);
      expect(fitted.zoom, fit(0).zoom);
      expect(
        (fitted.latLngToScreenOffset(coordinate) - viewport.center).distance,
        lessThan(0.1),
      );
    });
  });
}
