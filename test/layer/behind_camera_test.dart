import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/shared/near_clip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

const _size = Size(400, 300);
const _center = LatLng(45.5, -122.6);
const _background = Color(0xFF0000FF);
const _red = Color(0xFFFF0000);

final _boundary = GlobalKey();

MapCamera _camera({double pitch = 85, double rotation = 30}) => MapCamera(
      crs: const Epsg3857(),
      center: _center,
      zoom: 12,
      rotation: rotation,
      nonRotatedSize: _size,
      pitch: pitch,
    );

/// [camera]'s transform from its layer canvas to the screen.
Matrix4 _canvasToScreen(MapCamera camera) {
  final origin = camera.pixelOrigin;
  return camera.pixelToScreenTransform
    ..multiply(Matrix4.translationValues(origin.dx, origin.dy, 0));
}

double _divisor(Matrix4 m, Offset p) =>
    m.storage[3] * p.dx + m.storage[7] * p.dy + m.storage[15];

Offset _canvas(MapCamera camera, LatLng point) =>
    camera.projectAtZoom(point) - camera.pixelOrigin;

Future<MapController> _pump(
  WidgetTester tester, {
  required List<Widget> children,
}) async {
  final controller = MapController();
  await tester.pumpWidget(MaterialApp(
    home: Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: _boundary,
        child: SizedBox.fromSize(
          size: _size,
          child: FlutterMap(
            mapController: controller,
            options: const MapOptions(
              initialCenter: _center,
              initialZoom: 12,
              initialRotation: 30,
              initialPitch: 85,
              maxPitch: 85,
              backgroundColor: _background,
            ),
            children: children,
          ),
        ),
      ),
    ),
  ));
  return controller;
}

Future<Color Function(int x, int y)> _render(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final data = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    return image.toByteData();
  }))!;
  return (int x, int y) {
    final value = data.getUint32((y * _size.width.toInt() + x) * 4);
    return Color(((value & 0xFF) << 24) | (value >> 8));
  };
}

void main() {
  group('near clip', () {
    test('is null at pitch 0', () {
      expect(NearClip.of(_camera(pitch: 0)), isNull);
    });

    test('keeps a polygon in front of the camera', () {
      final camera = _camera();
      final clip = NearClip.of(camera)!;
      final ring = [
        for (final (lat, lng) in const [
          (45.6, -122.7),
          (45.6, -122.5),
          (45.45, -122.5),
          (45.45, -122.7),
        ])
          _canvas(camera, LatLng(lat, lng)),
      ];
      expect(clip.contains(ring), isTrue);
      expect(identical(clip.ring(ring), ring), isTrue);
    });

    for (final rotation in [0.0, 30.0]) {
      test('clips a polygon behind the camera, rotation $rotation', () {
        final camera = _camera(rotation: rotation);
        final clip = NearClip.of(camera)!;
        final toScreen = _canvasToScreen(camera);
        final behind = _canvas(camera, const LatLng(40, -122.6));
        expect(_divisor(toScreen, behind), lessThan(0));

        final ring = [
          _canvas(camera, const LatLng(46, -122.7)),
          _canvas(camera, const LatLng(46, -122.5)),
          _canvas(camera, const LatLng(40, -122.5)),
          _canvas(camera, const LatLng(40, -122.7)),
        ];
        final clipped = clip.ring(ring);
        expect(clipped, hasLength(4));
        for (final p in clipped) {
          expect(_divisor(toScreen, p), greaterThan(0));
        }
        for (final p in clipped.where((p) => !ring.contains(p))) {
          expect(MatrixUtils.transformPoint(toScreen, p).dy,
              greaterThan(_size.height));
        }
        expect(
            clip.ring([behind, behind + const Offset(10, 0), behind]), isEmpty);
      });
    }
  });

  testWidgets('polygon reaching behind the camera', (tester) async {
    final controller = await _pump(tester, children: [
      PolygonLayer(polygons: [
        Polygon(
          points: const [
            LatLng(65, -122.62),
            LatLng(65, -122.58),
            LatLng(40, -122.58),
            LatLng(40, -122.62),
          ],
          color: _red,
        ),
      ]),
    ]);
    final pixel = await _render(tester);
    final camera = controller.camera;
    bool inside(Offset p) {
      final c = camera.screenOffsetToLatLng(p);
      return c.longitude > -122.62 && c.longitude < -122.58;
    }

    var red = 0;
    for (var y = 0; y < 300; y += 3) {
      if ((y - camera.farLimit).abs() < 2) continue;
      for (var x = 0; x < 400; x += 2) {
        final Color expected;
        if (y < camera.farLimit) {
          expected = _background;
        } else {
          final center = Offset(x + 0.5, y + 0.5);
          final neighbors = {
            for (final d in const [-3.0, 0.0, 3.0])
              for (final e in const [-3.0, 0.0, 3.0])
                inside(center + Offset(d, e)),
          };
          if (neighbors.length > 1) continue;
          expected = neighbors.single ? _red : _background;
          if (neighbors.single) red++;
        }
        expect(pixel(x, y), expected, reason: '($x, $y)');
      }
    }
    expect(red, greaterThan(50));
  });
}
