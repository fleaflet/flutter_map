import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

MapCamera _camera({double pitch = 60, double rotation = 30}) => MapCamera(
      crs: const Epsg3857(),
      center: const LatLng(45.5, -122.6),
      zoom: 10,
      rotation: rotation,
      nonRotatedSize: const Size(400, 300),
      pitch: pitch,
    );

Offset _round(Offset o) => Offset(o.dx.roundToDouble(), o.dy.roundToDouble());

void main() {
  test('visible bounds contain the coordinates across the viewport', () {
    final camera = _camera();
    final bounds = camera.visibleBounds;
    for (double x = 0; x <= 400; x += 100) {
      for (double y = 0; y <= 300; y += 75) {
        final coordinate = camera.screenOffsetToLatLng(Offset(x, y));
        expect(bounds.contains(coordinate), isTrue, reason: '($x, $y)');
      }
    }
  });

  test('pixel bounds, origin and size describe the same rectangle', () {
    final camera = _camera();
    expect(camera.pixelBounds.topLeft, camera.pixelOrigin);
    expect(camera.pixelBounds.size, camera.size);
    for (double x = 0; x <= 400; x += 100) {
      for (double y = 0; y <= 300; y += 75) {
        final pixel =
            camera.projectAtZoom(camera.screenOffsetToLatLng(Offset(x, y)));
        expect(camera.pixelBounds.inflate(1e-6).contains(pixel), isTrue,
            reason: '($x, $y)');
      }
    }
  });

  test('far edge extends further than the near edge', () {
    final camera = _camera(rotation: 0);
    final center = camera.projectAtZoom(camera.center);
    expect(center.dy - camera.pixelBounds.top,
        greaterThan(3 * (camera.pixelBounds.bottom - center.dy)));
    expect(camera.size.width, greaterThan(2 * 400));
  });

  test('pixel bounds and origin at another center and zoom', () {
    final camera = _camera();
    const center = LatLng(45.6, -122.4);
    final moved = camera.withPosition(center: center, zoom: 11);
    expect(camera.getNewPixelOrigin(center, 11), _round(moved.pixelOrigin));
    final atZoom = camera.pixelBoundsAtZoom(11);
    expect(atZoom.size.width, closeTo(camera.size.width * 2, 1e-6));
    expect(atZoom.size.height, closeTo(camera.size.height * 2, 1e-6));
  });

  test('values at pitch 0 are unchanged', () {
    for (final rotation in [0.0, 30.0]) {
      final camera = _camera(pitch: 0, rotation: rotation);
      final projectedCenter = camera.projectAtZoom(camera.center);
      final size =
          MapCamera.calculateRotatedSize(rotation, const Size(400, 300));
      expect(camera.size, size);
      expect(camera.pixelOrigin, projectedCenter - size.center(Offset.zero));
      expect(
        camera.pixelBounds,
        Rect.fromCenter(
          center: Offset(projectedCenter.dx.floorToDouble(),
              projectedCenter.dy.floorToDouble()),
          width: size.width,
          height: size.height,
        ),
      );
      expect(
        camera.getNewPixelOrigin(camera.center),
        _round(projectedCenter - size.center(Offset.zero)),
      );
    }
  });
}
