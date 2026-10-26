import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'pitch_reference_data.dart';

const _phone = Size(393, 851);

MapCamera _camera({
  double pitch = 85,
  double rotation = 30,
  Size size = _phone,
}) =>
    MapCamera(
      crs: const Epsg3857(),
      center: const LatLng(45.5, -122.6),
      zoom: 10,
      rotation: rotation,
      nonRotatedSize: size,
      pitch: pitch,
    );

/// The screen position of [coordinate] in MapLibre Native's camera model,
/// computed from the camera's geometry instead of a matrix.
Offset _model(MapCamera camera, LatLng coordinate) {
  final ground =
      camera.projectAtZoom(coordinate) - camera.projectAtZoom(camera.center);
  final angle = camera.rotationRad;
  final x = ground.dx * cos(angle) - ground.dy * sin(angle);
  final y = ground.dx * sin(angle) + ground.dy * cos(angle);
  final size = camera.nonRotatedSize;
  final distance = size.height / 2 / tan(MapCamera.fieldOfView / 2);
  final depth = distance - y * sin(camera.pitchRad);
  return Offset(
    size.width / 2 + distance * x / depth,
    size.height / 2 + distance * y * cos(camera.pitchRad) / depth,
  );
}

/// The angle, in degrees, between the view ray through screen row [y] and
/// straight down.
double _rayAngle(MapCamera camera, double y) {
  final distance =
      camera.nonRotatedSize.height / 2 / tan(MapCamera.fieldOfView / 2);
  return camera.pitch +
      atan((camera.nonRotatedSize.height / 2 - y) / distance) * 180 / pi;
}

/// Screen positions in a grid over the viewport below the far limit.
Iterable<Offset> _belowFarLimit(MapCamera camera) sync* {
  final top = camera.groundViewport.top;
  final size = camera.nonRotatedSize;
  for (var i = 0; i <= 6; i++) {
    for (var j = 0; j <= 8; j++) {
      yield Offset(size.width * i / 6, top + (size.height - top) * j / 8);
    }
  }
}

void main() {
  group('far limit', () {
    test('is in the viewport only above 70.82 degrees', () {
      final below = _camera(pitch: 70.81);
      expect(below.farLimit, lessThan(0));
      expect(below.groundViewport, Offset.zero & _phone);
      final above = _camera(pitch: 70.82);
      expect(above.farLimit, greaterThan(0));
      expect(above.groundViewport.top, above.farLimit);
    });

    test('position at pitch 85', () {
      final camera = _camera();
      expect(camera.farLimit, closeTo(330.6, 0.1));
      expect(_rayAngle(camera, camera.farLimit), closeTo(89.25, 1e-9));
      expect(
        camera.groundViewport,
        Rect.fromLTRB(0, camera.farLimit, _phone.width, _phone.height),
      );
    });

    test('is above any position at pitch 0', () {
      expect(_camera(pitch: 0).farLimit, double.negativeInfinity);
    });
  });

  group('footprint', () {
    test('at pitch 60 is unchanged', () {
      final camera = _camera(pitch: 60, size: const Size(400, 300));
      expect(camera.size.width, 969.6152422706655);
      expect(camera.size.height, 1079.4228634059837);
      expect(camera.pixelOrigin,
          const Offset(41032.693012741445, 92931.28022360068));
      final bounds = camera.visibleBounds;
      expect(bounds.south, 45.28000510786582);
      expect(bounds.west, -123.65017133870347);
      expect(bounds.north, 46.31347281706326);
      expect(bounds.east, -122.3186074378801);
    });

    for (final rotation in [0.0, 30.0]) {
      test('visible bounds at pitch 85, rotation $rotation', () {
        final camera = _camera(rotation: rotation);
        final bounds = camera.visibleBounds;
        for (final value in [
          bounds.south,
          bounds.west,
          bounds.north,
          bounds.east,
        ]) {
          expect(value.isFinite, isTrue);
        }
        final farLimit = camera.farLimit;
        for (final corner in [
          const Offset(0, 851),
          const Offset(393, 851),
          Offset(0, farLimit),
          Offset(393, farLimit),
        ]) {
          final coordinate = camera.screenOffsetToLatLng(corner);
          expect(coordinate.latitude,
              inInclusiveRange(bounds.south - 1e-9, bounds.north + 1e-9),
              reason: '$corner');
          expect(coordinate.longitude,
              inInclusiveRange(bounds.west - 1e-9, bounds.east + 1e-9),
              reason: '$corner');
        }
        for (final position in _belowFarLimit(camera)) {
          final pixel =
              camera.projectAtZoom(camera.screenOffsetToLatLng(position));
          expect(camera.pixelBounds.inflate(1e-6).contains(pixel), isTrue,
              reason: '$position');
        }
        expect(camera.pixelBounds.topLeft, camera.pixelOrigin);
        expect(camera.pixelBounds.size, camera.size);
      });
    }
  });

  group('conversions', () {
    test('the model matches MapLibre Native at the reference cameras', () {
      for (final reference in referenceCameras) {
        final camera = MapCamera(
          crs: const Epsg3857(),
          center: LatLng(reference.latitude, reference.longitude),
          zoom: reference.zoom,
          rotation: reference.rotation,
          nonRotatedSize: Size(reference.width, reference.height),
          pitch: reference.pitch,
        );
        for (final point in reference.points) {
          final screen =
              _model(camera, LatLng(point.latitude, point.longitude));
          expect(screen.dx, closeTo(point.x, 0.01));
          expect(screen.dy, closeTo(point.y, 0.01));
        }
      }
    });

    for (final pitch in [60.0, 85.0]) {
      test('matches the camera model at pitch $pitch', () {
        final camera = _camera(pitch: pitch);
        for (final position in _belowFarLimit(camera)) {
          final coordinate = camera.screenOffsetToLatLng(position);
          final model = _model(camera, coordinate);
          expect((model - position).distance, lessThan(0.01),
              reason: '$position');
          expect(
            (camera.latLngToScreenOffset(coordinate) - model).distance,
            lessThan(0.01),
            reason: '$position',
          );
        }
      });
    }

    test('round trip at pitch 85', () {
      final camera = _camera();
      for (final position in _belowFarLimit(camera)) {
        final coordinate = camera.maybeScreenOffsetToLatLng(position);
        expect(coordinate, camera.screenOffsetToLatLng(position));
        final screen = camera.latLngToScreenOffset(coordinate!);
        expect((screen - position).distance, lessThan(0.01),
            reason: '$position');
      }
    });

    test('above the far limit', () {
      final camera = _camera();
      for (final position in [
        Offset(100, camera.farLimit - 0.01),
        const Offset(300, 314),
        const Offset(200, 0),
        const Offset(50, -1000),
      ]) {
        final onFarLimit = Offset(position.dx, camera.farLimit);
        expect(camera.maybeScreenOffsetToLatLng(position), isNull);
        expect(camera.groundOffsetFromCenter(position), isNull);
        expect(camera.screenOffsetToLatLng(position),
            camera.screenOffsetToLatLng(onFarLimit));
        expect(camera.offsetToCrs(position), camera.offsetToCrs(onFarLimit));
      }
    });

    test('above the horizon at pitch 60', () {
      final camera = _camera(pitch: 60);
      const above = Offset(200, -2000);
      expect(camera.maybeScreenOffsetToLatLng(above), isNull);
      expect(camera.screenOffsetToLatLng(above),
          camera.screenOffsetToLatLng(Offset(200, camera.farLimit)));
    });

    test('focusedZoomCenter above the far limit keeps the far limit', () {
      final camera = _camera();
      final onFarLimit = Offset(100, camera.farLimit);
      final coordinate = camera.screenOffsetToLatLng(onFarLimit);
      final zoomed = camera.withPosition(
        center: camera.focusedZoomCenter(const Offset(100, 100), 10.5),
        zoom: 10.5,
      );
      expect(
        (zoomed.latLngToScreenOffset(coordinate) - onFarLimit).distance,
        lessThan(0.5),
      );
    });
  });
}
